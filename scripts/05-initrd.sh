OUTPUT_FILE="/opt/output/kernel/initrd.img-${KERNEL_VERSION}"
uInitrd_FILE="/opt/output/kernel/uInitrd-${KERNEL_VERSION}"

echo "[✨] Creating initrd.img"
if [ ! -f $OUTPUT_FILE ] 
then
    chroot ${ROOTFS_DIR} /bin/bash -c '
        CONF=/etc/initramfs-tools/update-initramfs.conf
        if grep -q "^COMPRESS=" "$CONF"; then
            sed -i "s/^COMPRESS=.*/COMPRESS=gzip/" "$CONF"
        else
            echo "COMPRESS=gzip" >> "$CONF"
        fi
    '
     chroot ${ROOTFS_DIR} /bin/bash -c '
        CONF=/etc/initramfs-tools/initramfs.conf
        if grep -q "^COMPRESS=" "$CONF"; then
            sed -i "s/^COMPRESS=.*/COMPRESS=gzip/" "$CONF"
        else
            echo "COMPRESS=gzip" >> "$CONF"
        fi
    '
    chroot ${ROOTFS_DIR} /bin/bash -c "update-initramfs -c -k $KERNEL_VERSION"
    mv ${ROOTFS_DIR}/boot/initrd.img-${KERNEL_VERSION} $OUTPUT_FILE

else
    echo "[♻️] Skipping initrd.img creation, using pre-built version from $OUTPUT_FILE"
    sha256sum $OUTPUT_FILE
fi


if [ ! -f $uInitrd_FILE ] 
then
    mkimage -A arm64 -T ramdisk -C gzip -n "initrd $KERNEL_VERSION" -d $OUTPUT_FILE $uInitrd_FILE
fi