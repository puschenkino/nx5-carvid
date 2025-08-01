FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# u-boot build dependencies
RUN apt update && apt install -y \
    git build-essential gcc-aarch64-linux-gnu \
    bison flex libssl-dev make \
    python3 python3-pyelftools \
    device-tree-compiler \
    sudo wget curl \
    && apt clean

# debootstrap dependencies
RUN apt install -y debootstrap qemu-user-static

WORKDIR /src