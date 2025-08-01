#!/bin/bash
set -e

UBOOT_REPO="https://github.com/radxa/u-boot.git"
#KERNEL_REPO="https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git"
#KERNEL_BRANCH="v6.16"

KERNEL_REPO="https://github.com/radxa/kernel"
KERNEL_BRANCH="linux-6.1-stan-rkr5.1"
ROOTFS_DIR="/opt/build/rootfs"
IMG_NAME="/opt/output/radxa_debian.img"

if [ ! -d "/opt/build/rkbin" ] 
then
    echo "[✨] getting rkbin tooling ..."
    cd /opt/build
    git clone -v https://github.com/radxa/rkbin.git rkbin
fi

# # 1. U-Boot       
echo "[✨] Cloning and building U-Boot..."
if [ ! -d "/opt/output/uboot" ] 
then

    if [ ! -d "/opt/build/uboot" ] 
    then
        git clone -v -b next-dev-v2024.10 $UBOOT_REPO uboot
    fi  

    cp /opt/configs/u-boot/radxa-nx5-carmod-rk3588s_defconfig /opt/build/uboot/configs/radxa-nx5-carmod-rk3588s_defconfig
    cp /opt/configs/u-boot/rk3588-radxa-nx5-carmod.dts /opt/build/uboot/arch/arm/dts/
    
    export CROSS_COMPILE=aarch64-linux-gnu-
    export KCFLAGS="-Wno-error"
    
    cd /opt/build/uboot/
    mkdir -p /opt/output/uboot
    make radxa-nx5-carmod-rk3588s_defconfig
    make -j$(nproc) -o /opt/output/uboot
    tools/mkimage -n rk3588 -T rksd -d /opt/build/uboot/spl/u-boot-spl.bin /opt/output/uboot/idbloader.img
    cp /opt/build/rkbin/bin/rk35/bl31.elf bl31.elf 2>/dev/null || true
    /opt/build/uboot/make.sh CROSS_COMPILE=aarch64-linux-gnu- itb
    cp /opt/build/uboot/u-boot.itb /opt/output/uboot/u-boot.itb

else
   echo "Skipping U-Boot build, using pre-built version from /opt/output/uboot"
fi

# 2. Kernel
echo "[✨] Cloning and building Kernel..."
if [ ! -d "/opt/output/kernel" ] 
then
    cd /opt/build
    if [ ! -d "/opt/build/kernel" ] 
    then
        git clone -v -b $KERNEL_BRANCH $KERNEL_REPO kernel
    fi  
    
    cd /opt/build/kernel
    cp /opt/configs/kernel/rk3588_nx5-carmod_defconfig /opt/build/kernel/arch/arm64/configs
    cp /opt/configs/kernel/*.dts /opt/build/kernel/arch/arm64/boot/dts/rockchip
    cp /opt/configs/kernel/*.dtsi /opt/build/kernel/arch/arm64/boot/dts/rockchip
    cp /opt/configs/kernel/Makefile /opt/build/kernel/arch/arm64/boot/dts/rockchip/Makefile
    
    export CROSS_COMPILE=aarch64-linux-gnu-
    make ARCH=arm64 rk3588_nx5-carmod_defconfig
    make ARCH=arm64 -j$(nproc) Image dtbs modules
    make ARCH=arm64 INSTALL_MOD_PATH=../${ROOTFS_DIR} modules_install

    mkdir /opt/output/kernel
    cp /opt/build/kernel/arch/arm64/boot/Image /opt/output/kernel/Image
    cp /opt/build/kernel/arch/arm64/boot/dts/rockchip/rk3588-radxa-nx5-carmod.dtb /opt/output/kernel/rk3588-radxa-nx5-carmod.dtb
    cd ..
else
    echo "Skipping Kernel build, using pre-built version from /opt/output/kernel"
fi


# # 3. RootFS
echo "[✨] Creating Debian 12 (bookworm) rootfs..."
if [ ! -d "/opt/build/rootfs" ] 
then
mkdir -p ${ROOTFS_DIR}
sudo debootstrap --arch=arm64 --foreign bookworm ${ROOTFS_DIR} http://deb.debian.org/debian
sudo cp /usr/bin/qemu-aarch64-static ${ROOTFS_DIR}/usr/bin/
sudo chroot ${ROOTFS_DIR} /debootstrap/debootstrap --second-stage

# 4. SSH & Grundkonfiguration
echo "[✨] Configuring base system..."
sudo chroot ${ROOTFS_DIR} /bin/bash -c "
apt update && \
apt install -y openssh-server ifupdown sudo && \
systemctl enable ssh && \
echo 'root:radxa' | chpasswd
"
else
    echo "Skipping RootFS creation, using pre-built version from /opt/build/rootfs"
fi  


ROOTFS_DIR="/opt/build/rootfs"
IMG_NAME="/opt/output/radxa_debian.img"
UBOOT_DIR="/opt/output/uboot"
KERNEL_DIR="/opt/output/kernel"

# Sicherstellen, dass Output-Verzeichnis existiert
mkdir -p /opt/output

echo "[✨] Creating image file..."
rm -f ${IMG_NAME}
dd if=/dev/zero of=${IMG_NAME} bs=1M count=4096

echo "[✨] Creating partitions ..."
parted -s ${IMG_NAME} mklabel gpt
parted -s ${IMG_NAME} mkpart primary fat32 1MiB 128MiB
parted -s ${IMG_NAME} mkpart primary ext4 128MiB 100%

# Loop-Device einrichten
LOOPDEV=$(sudo losetup --find --show ${IMG_NAME})
echo "[🔁] Using loop device: ${LOOPDEV}"

# Partitionen mit kpartx erzeugen
sudo kpartx -av $LOOPDEV

BOOT_DEV="/dev/mapper/$(basename $LOOPDEV)p1"
ROOT_DEV="/dev/mapper/$(basename $LOOPDEV)p2"

# Warten, bis sie erscheinen
for i in {1..10}; do
    if [[ -b $BOOT_DEV && -b $ROOT_DEV ]]; then break; fi
    echo "⏳ Waiting for $BOOT_DEV and $ROOT_DEV..."
    sleep 0.5
done

if [[ ! -b $BOOT_DEV || ! -b $ROOT_DEV ]]; then
    echo "❌ Partition devices not found"
    sudo kpartx -dv $LOOPDEV
    sudo losetup -d $LOOPDEV
    exit 1
fi

# Formatieren
sudo mkfs.vfat $BOOT_DEV
sudo mkfs.ext4 $ROOT_DEV

# Mounten
mkdir -p mnt/boot mnt/root
sudo mount $BOOT_DEV mnt/boot
sudo mount $ROOT_DEV mnt/root

# Dateien kopieren
echo "[✨] Copying rootfs and kernel..."
sudo rsync -a ${ROOTFS_DIR}/ mnt/root/
sudo cp ${KERNEL_DIR}/Image mnt/boot/
sudo cp ${KERNEL_DIR}/rk3588-radxa-nx5-carmod.dtb mnt/boot/

# U-Boot installieren
echo "[✨] Installing U-Boot..."
sudo dd if=${UBOOT_DIR}/idbloader.img of=$LOOPDEV seek=64 conv=notrunc
sudo dd if=${UBOOT_DIR}/u-boot.itb of=$LOOPDEV seek=16384 conv=notrunc

# Aufräumen
sudo umount mnt/boot
sudo umount mnt/root
sudo kpartx -dv $LOOPDEV
sudo losetup -d $LOOPDEV

echo "[✓] Build complete. Image: ${IMG_NAME}"