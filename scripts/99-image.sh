echo "[✨] Creating image file..."
rm -f ${IMG_NAME}
dd if=/dev/zero of=${IMG_NAME} bs=1M count=1024

echo "[✨] Creating partitions ..."
parted -s ${IMG_NAME} mklabel gpt
parted -s ${IMG_NAME} mkpart primary fat32 1MiB 128MiB
parted -s ${IMG_NAME} mkpart primary ext4 128MiB 100%

# Loop-Device einrichten
LOOPDEV=$( losetup --find --show ${IMG_NAME})
echo "[🔁] Using loop device: ${LOOPDEV}"

# Partitionen mit kpartx erzeugen
 kpartx -av $LOOPDEV

BOOT_DEV="/dev/mapper/$(basename $LOOPDEV)p1"
ROOT_DEV="/dev/mapper/$(basename $LOOPDEV)p2"

# Warten, bis sie erscheinen
for i in {1..10}; do
    if [[ -b $BOOT_DEV && -b $ROOT_DEV ]]; then break; fi
    echo "⏳ Waiting for $BOOT_DEV and $ROOT_DEV..."s
    sleep 0.5
done

if [[ ! -b $BOOT_DEV || ! -b $ROOT_DEV ]]; then
    echo "❌ Partition devices not found"
     kpartx -dv $LOOPDEV
     losetup -d $LOOPDEV
    exit 1
fi

root_uuid="649161d6-d4d7-4cd1-acb8-453c16b78feb"

# Formatieren
 mkfs.vfat $BOOT_DEV 
 mkfs.ext4 -U ${root_uuid} $ROOT_DEV 

# Mounten
 mkdir -p mnt/boot mnt/root
 mount $BOOT_DEV mnt/boot
 mount $ROOT_DEV mnt/root 

# Dateien kopieren
echo "[🗾] Copying rootfs to root partition..."
rsync -a ${ROOTFS_DIR}/ mnt/root/

    # echo "[🗾] Copying initrd.img to boot partition..."
    # cp /opt/output/kernel/initrd.img-${KERNEL_VERSION} mnt/boot/

    # echo "[🗾] Copying Image to boot partition..."
    # cp /opt/output/kernel/Image-$KERNEL_VERSION mnt/boot/

    echo "[🗾] Copying uImage to boot partition..."
    cp /opt/output/kernel/uImage-$KERNEL_VERSION mnt/boot/

    echo "[🗾] Copying uInitrd to boot partition..."
    cp /opt/output/kernel/uInitrd-$KERNEL_VERSION mnt/boot/
    
    echo "[🗾] Copying rk3588-radxa-nx5-carmod.dtb to boot partition ..."
    cp /opt/output/kernel/rk3588-radxa-nx5-carmod.dtb mnt/boot/

echo "[❇️] LS mnt/boot/:"
ls -lah mnt/boot/

echo "[✨] Copying extlinux.conf ..."
    mkdir -p mnt/boot/extlinux/
    root_partuuid="$(blkid -s PARTUUID -o value "$ROOT_DEV")"
    echo "[❇️] RootPart UUID is: ${root_partuuid}"

echo "
TIMEOUT 10
DEFAULT uimagemixed
prompt 0
MENU TITLE Radxa NX5 CARMOD Boot Menu

LABEL image
    menu label primary image
    LINUX  /Image-${KERNEL_VERSION}
    INITRD /initrd.img-${KERNEL_VERSION}
    FDT /rk3588-radxa-nx5-carmod.dtb
    APPEND root=PARTUUID=${root_partuuid} console=ttyFIQ0,1500000n8 rw rootwait loglevel=4


LABEL uimage
    menu label primary uimage
    LINUX  /uImage-${KERNEL_VERSION}
    INITRD /uInitrd-${KERNEL_VERSION}
    FDT /rk3588-radxa-nx5-carmod.dtb
    APPEND root=PARTUUID=${root_partuuid} console=ttyFIQ0,1500000n8 rw rootwait loglevel=4

LABEL uimagemixed
    menu label primary uimagemixed
    LINUX  /Image-${KERNEL_VERSION}
    INITRD /uInitrd-${KERNEL_VERSION}
    FDT /rk3588-radxa-nx5-carmod.dtb
    APPEND root=PARTUUID=${root_partuuid} console=ttyFIQ0,1500000n8 rw rootwait loglevel=4


" > mnt/boot/extlinux/extlinux.conf

# U-Boot installieren
echo "[✨] Installing U-Boot..."
    dd if=${UBOOT_COLLABORA_DIR}/idbloader.img of=$LOOPDEV seek=64 conv=notrunc
    dd if=${UBOOT_COLLABORA_DIR}/u-boot.itb of=$LOOPDEV seek=16384 conv=notrunc

    # Aufräumen
    umount mnt/boot
    umount mnt/root
    kpartx -dv $LOOPDEV
    losetup -d $LOOPDEV
