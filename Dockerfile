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

WORKDIR /opt/build

ENTRYPOINT ["/opt/build.sh"]
