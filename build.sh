#!/bin/bash
set -e

UBOOT_REPO="https://github.com/radxa/u-boot.git"
UBOOT_BRANCH="next-dev-v2024.10"

KERNEL_REPO="https://github.com/radxa/kernel"
KERNEL_BRANCH="linux-6.1-stan-rkr5.1"

export ROOTFS_DIR="/opt/build/rootfs"
export IMG_NAME="/opt/output/radxa_debian.img"

export UBOOT_DIR="/opt/output/uboot"
export UBOOT_COLLABORA_DIR="/opt/output/u-boot-collabora"

export KERNEL_DIR="/opt/output/kernel"


#1 u-boot
if [ ! -d "/opt/build/rkbin" ] 
then
    echo "[✨] getting rkbin tooling ..."
    cd /opt/build
    git clone --depth 1 https://github.com/radxa/rkbin.git rkbin
fi

if [ ! -d "/opt/build/u-boot" ] 
then
    echo "[✨] Cloning radxa u-boot branch: $UBOOT_BRANCH ..."
    cd /opt/build
    git clone --depth 1 -b $UBOOT_BRANCH $UBOOT_REPO u-boot
fi  

if [ ! -d "/opt/build/build" ] 
then
    echo "[✨] Cloning radxa build helper ..."
    cd /opt/build
    git clone --depth 1 -b debian https://github.com/radxa/build.git build
fi  

if [ ! -d "/opt/build/kernel" ] 
then
    cd /opt/build
    echo "[✨] Cloning kernel branch: $KERNEL_BRANCH ..."
    git clone --depth 1 -b $KERNEL_BRANCH $KERNEL_REPO kernel
fi 

 cd /opt/build/kernel
export KERNEL_VERSION=$(make -s kernelrelease) 
echo "[🌲] Kernelrelease: $KERNEL_VERSION"


for f in /opt/scripts/*.sh; do
    echo "[📃] ---- executing $f"
    bash "$f" 
done





echo "[✓] Build complete. Image: ${IMG_NAME}"
