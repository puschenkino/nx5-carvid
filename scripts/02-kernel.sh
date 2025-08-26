
cd /opt/build/kernel
mkdir -p /opt/output

# 2. Kernel
echo "[✨] Building Kernel..."
if [ ! -f "/opt/output/kernel/Image-$KERNEL_VERSION" ] 
then
    cd /opt/build/kernel
    cp /opt/configs/kernel/rk3588_nx5-carmod_defconfig /opt/build/kernel/arch/arm64/configs
    cp /opt/configs/kernel/*.dts /opt/build/kernel/arch/arm64/boot/dts/rockchip
    cp /opt/configs/kernel/*.dtsi /opt/build/kernel/arch/arm64/boot/dts/rockchip
    cp /opt/configs/kernel/Makefile /opt/build/kernel/arch/arm64/boot/dts/rockchip/Makefile
    
    export CROSS_COMPILE=aarch64-linux-gnu-
    make ARCH=arm64 rk3588_nx5-carmod_defconfig
    make ARCH=arm64 -j$(nproc) Image modules
    mkdir -p /opt/output/kernel/modules
    make ARCH=arm64 INSTALL_MOD_PATH=/opt/output/kernel/modules modules_install

    cp /opt/build/kernel/arch/arm64/boot/Image /opt/output/kernel/Image-$KERNEL_VERSION
    cp /opt/build/kernel/arch/arm64/configs/rk3588_nx5-carmod_defconfig /opt/output/kernel/rk3588_nx5-carmod_defconfig
else
    echo "[♻️] Skipping Kernel build, using pre-built version from /opt/output/kernel/Image-$KERNEL_VERSION"
fi


if [ ! -f "/opt/output/kernel/rk3588-radxa-nx5-carmod.dtb" ] 
then
    echo "[✨] Building DTB ..."
    cd /opt/build/kernel
    cp /opt/configs/kernel/*.dts /opt/build/kernel/arch/arm64/boot/dts/rockchip
    export CROSS_COMPILE=aarch64-linux-gnu-
    make ARCH=arm64 -j$(nproc) dtbs
    cp /opt/build/kernel/arch/arm64/boot/dts/rockchip/rk3588-radxa-nx5-carmod.dtb /opt/output/kernel/rk3588-radxa-nx5-carmod.dtb
else
    echo "[♻️] Skipping DTB build, using pre-built version from /opt/output/kernel/rk3588-radxa-nx5-carmod.dtb"
fi