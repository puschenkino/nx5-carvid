#!/bin/bash
set -e

echo "📦 Baue U-Boot..."
UBOOT_REPO="https://github.com/radxa/u-boot.git"
UBOOT_BRANCH="next-dev-v2024.10"
DEFCONFIG="radxa-nx5-carvid-rk3588s_defconfig"

if [ ! -d u-boot ]; then
  git clone --depth=1 -b "$UBOOT_BRANCH" "$UBOOT_REPO"
fi

cd u-boot
cp /configs/u-boot/rk3588-radxa-nx5-carvid.dts arch/arm/dts/rk3588-radxa-nx5-carvid.dts
cp /configs/u-boot/radxa-nx5-carvid-rk3588s_defconfig configs/radxa-nx5-carvid-rk3588s_defconfig
make distclean
make ${DEFCONFIG}
make CROSS_COMPILE=aarch64-linux-gnu- -j$(nproc)
cp u-boot.img /output/
