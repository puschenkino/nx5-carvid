
echo "[✨] Building uImage..."
if [ ! -f "/opt/output/kernel/uImage-$KERNEL_VERSION" ] 
then
    cd /opt/build/kernel
    mkimage -A arm64 -O linux -T kernel -C none -a 0x00280000 -e 0x00280000 -n "Linux $KERNEL_VERSION" -d arch/arm64/boot/Image /opt/output/kernel/uImage-$KERNEL_VERSION
else
    echo "[♻️] Skipping Kernel build, using pre-built version from /opt/output/kernel/uImage"
fi