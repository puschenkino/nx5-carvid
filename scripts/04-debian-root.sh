
echo "[✨] Creating Debian rootfs..."
if [ ! -d ${ROOTFS_DIR} ] 
then
    mkdir -p ${ROOTFS_DIR}
    debootstrap --arch=arm64 --foreign bookworm ${ROOTFS_DIR} http://deb.debian.org/debian
    cp /usr/bin/qemu-aarch64-static ${ROOTFS_DIR}/usr/bin/
    chroot ${ROOTFS_DIR} /debootstrap/debootstrap --second-stage
 
    # 4. SSH & Grundkonfiguration
    echo "[✨] Configuring base system..."
    cp /opt/output/kernel/rk3588_nx5-carmod_defconfig ${ROOTFS_DIR}/boot/config-${KERNEL_VERSION}
    cp /opt/output/kernel/linux-headers-6.1.115+_arm64.deb ${ROOTFS_DIR}/tmp/
    cp /opt/output/kernel/linux-image-6.1.115+_arm64.deb ${ROOTFS_DIR}/tmp/
    chroot ${ROOTFS_DIR} dpkg -i /tmp/linux-headers-6.1.115+_arm64.deb
    chroot ${ROOTFS_DIR} dpkg -i /tmp/linux-image-6.1.115+_arm64.deb
    

    # move kernel modules
    
    # mkdir -p ${ROOTFS_DIR}/lib/modules/${KERNEL_VERSION}
    #cp -a /opt/output/kernel/modules/lib/modules/${KERNEL_VERSION}/* ${ROOTFS_DIR}/lib/modules/${KERNEL_VERSION}/
    #chroot ${ROOTFS_DIR} depmod -a ${KERNEL_VERSION}

    chroot ${ROOTFS_DIR} /bin/bash -c "
    apt update && \
    apt install -y cloud-initramfs-growroot openssh-server ifupdown locales initramfs-tools systemd-sysv login sudo udev netbase ifupdown curl systemd-resolved systemd-timesyncd i2c-tools lm-sensors && \
    systemctl enable ssh && \
    systemctl enable systemd-resolved.service && \
    systemctl enable systemd-timesyncd.service && \
    systemctl enable systemd-networkd.service && \
    systemctl enable serial-getty@ttyFIQ0.service && \
    echo 'root:radxa' | chpasswd
    "

    chroot ${ROOTFS_DIR} /bin/bash -c "
    rm /etc/resolv.conf && ln -s /run/systemd/resolve/resolv.conf /etc/resolv.conf
    "

echo "[Match]
Name=end1*

[Network]
DHCP=yes" > ${ROOTFS_DIR}/etc/systemd/network/20-dhcp.network
 
else
    echo "[♻️] Skipping RootFS creation, using pre-built version from /opt/build/rootfs"
fi