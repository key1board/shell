#!/bin/bash

# cat > images.txt <<EOF
# gcr.io/k8s-staging-sig-storage/objectstorage-sidecar/objectstorage-sidecar:v20230130-v0.1.0-24-gc0cf995
# quay.io/ceph/ceph:v17.2.6
# quay.io/ceph/cosi:v0.1.1
# quay.io/cephcsi/cephcsi:v3.9.0
# quay.io/csiaddons/k8s-sidecar:v0.7.0
# registry.k8s.io/sig-storage/csi-attacher:v4.3.0
# registry.k8s.io/sig-storage/csi-node-driver-registrar:v2.8.0
# registry.k8s.io/sig-storage/csi-provisioner:v3.5.0
# registry.k8s.io/sig-storage/csi-resizer:v1.8.0
# registry.k8s.io/sig-storage/csi-snapshotter:v6.2.2
# rook/ceph:v1.12.9
# EOF
#给谷歌服务器用

function up {
    # 读取 images.txt 文件中的每一行
    while IFS= read -r line; do
        # 使用 docker pull 命令来拉取镜像
        docker pull "$line"

        # 获取镜像的名称和标签
        image_name=$(echo "$line" | awk -F'[/:]' '{print $(NF-1)}')
        image_tag=$(echo "$line" | cut -d ":" -f 2)

        docker tag $lineregistry.cn-hangzhou.aliyuncs.com/image-acr/${image_name}:${image_tag}
        docker push "registry.cn-hangzhou.aliyuncs.com/image-acr/${image_name}:${image_tag}"
        echo "新镜像地址为: registry.cn-hangzhou.aliyuncs.com/image-acr/${image_name}:${image_tag}"

    done <images.txt
}


function save {
    # 读取 images.txt 文件中的每一行
    while IFS= read -r line; do
        # 使用 docker pull 命令来拉取镜像
        docker pull "$line"

        # 获取镜像的名称和标签
        image_name=$(echo "$line" | awk -F'[/:]' '{print $(NF-1)}')
        image_tag=$(echo "$line" | cut -d ":" -f 2)

        # 使用 docker save 命令来将镜像保存到本地
        docker save "$line" -o "$image_name"_"$image_tag".tar
        echo "已保存: ${image_name}_${image_tag}.tar"
    done <images.txt

}

#加载当前当前目录所有镜像
function load {
    images=$(ls *.tar)
    for line in $images; do
        docker load -i $line
    done
}

#将阿里仓库镜像换成原仓库地址
function down {
    while IFS= read -r new_tag; do
        # 拉取阿里仓库
        image_name=$(echo ${new_tag} | awk -F'[/:]' '{print $(NF-1)}')
        image_version=$(echo ${new_tag} | awk -F ':' '{print $2}')
        ali_image=$(echo "registry.cn-hangzhou.aliyuncs.com/image-acr/${image_name}:${image_version}")
        #docker pull ${ali_image}

        #将拉取的镜像替换为原镜像名
        #docker tag ${ali_image} $new_tag
        #如果是containerd使用下面的命令
        crictl pull ${ali_image}
        #将拉取的镜像替换为原镜像名
        ctr -n k8s.io i  tag ${ali_image} $new_tag

        echo "已替换: $new_tag"
    done <images.txt
}

case $1 in
up)
    up
    ;;
load)
    load
    ;;
save)
    save
    ;;
down)
    down
    ;;
*)
    echo "save | load | new_tag | restore"
    ;;
esac