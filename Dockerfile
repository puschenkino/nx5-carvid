FROM debian:bookworm

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    build-essential git wget curl unzip bc bison flex \
    libssl-dev libncurses5-dev libncursesw5-dev \
    device-tree-compiler u-boot-tools \
    qemu-user-static debootstrap \
    parted dosfstools \
    rsync binfmt-support \
    sudo fakeroot ca-certificates \
    fdisk kmod

RUN apt-get install -y \
  gcc-aarch64-linux-gnu g++-aarch64-linux-gnu kpartx python-is-python3 python3-pyelftools file bsdextrautils

# collabora u-boot tools
RUN apt-get install -y \
  bc build-essential crossbuild-essential-arm64 device-tree-compiler git python3 bison flex lzop python3-setuptools \
  swig python3-dev libssl-dev python3-pyelftools uuid-dev gnutls-dev python3-pyelftools python3-setuptools
WORKDIR /opt/build

ENTRYPOINT ["/opt/build.sh"]
