
if [ ! -f "/opt/output/uboot/idbloader.img" ] 
then
    echo "[✨] prepare build env u-boot"
    export ARCH=arm
    export CROSS_COMPILE=aarch64-linux-gnu-

    mkdir -p /opt/output/uboot
    cp /opt/configs/u-boot/radxa-nx5-carmod-rk3588s_defconfig /opt/build/u-boot/configs/radxa-nx5-carmod-rk3588s_defconfig
    cp /opt/configs/u-boot/rk3588-radxa-nx5-carmod.dts /opt/build/u-boot/arch/arm/dts/
    cp /opt/configs/u-boot/decode_bl31.py /opt/build/u-boot/arch/arm/mach-rockchip/

    cd /opt/build/u-boot
    
    echo "[🛠️] configuring make radxa-nx5-carmod-rk3588s_defconfig"
    make radxa-nx5-carmod-rk3588s_defconfig

    echo "[🛠️] Buildung u-boot.itb"
    make spl/u-boot-spl.bin u-boot.dtb u-boot.itb
    cp u-boot.itb /opt/output/uboot/

    echo "[🛠️] Buildung idbloader.img"
    ./tools/mkimage -n rk3588 -T rksd -d ../rkbin/bin/rk35/rk3588_ddr_lp4_2112MHz_lp5_2400MHz_v1.19.bin:spl/u-boot-spl.bin idbloader.img
    cp idbloader.img /opt/output/uboot/

    echo "[🛠️] Nice to have ... rk3588_spl_loader_v1.19.113.bin"
    cp ../rkbin/bin/rk35/rk3588_spl_loader_v1.19.113.bin /opt/output/uboot/
else
    echo "Skipping idbloader.img build, using pre-built version from /opt/output/uboot/idbloader.img"
fi  