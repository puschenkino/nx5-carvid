UBOOT_COLAB_REPO="https://gitlab.collabora.com/hardware-enablement/rockchip-3588/u-boot.git"
UBOOT_COLAB_BRANCH="rockchip"
foldername="u-boot-collabora"
BUILDCONFIG="generic-rk3588_defconfig"
export BL31="../rkbin/bin/rk35/rk3588_bl31_v1.50.elf"
export ROCKCHIP_TPL="../rkbin/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.19.bin"
export MINIALL_FILE="RKBOOT/RK3588MINIALL.ini"

export CROSS_COMPILE="aarch64-linux-gnu-"
export ARCH="arm64"
export GIT_STRATEGY="fetch"
export GIT_DEPTH="1"

if [ ! -d "/opt/build/${foldername}" ] 
then
    echo "[✨] getting rkbin u-boot collabora branch: ${UBOOT_COLAB_BRANCH} ..."
    cd /opt/build
    git clone --depth 1 ${UBOOT_COLAB_REPO} -b ${UBOOT_COLAB_BRANCH} u-boot-collabora
fi

if [ ! -f "/opt/output/${foldername}/idbloader.img" ] 
then
    echo "[🛠️] building collabora u-boot with ${BUILDCONFIG}"
    cd /opt/build/u-boot-collabora
    make ${BUILDCONFIG}
    make -j$(nproc)

    mkdir -p /opt/output/${foldername}/
    cp u-boot.itb /opt/output/${foldername}/
    cp idbloader.img /opt/output/${foldername}/
else
    echo "skipping building collabora u-boot with ${BUILDCONFIG}"
fi