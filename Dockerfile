FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt update && apt install -y \
    git build-essential gcc-aarch64-linux-gnu \
    bison flex libssl-dev make \
    python3 python3-pyelftools \
    device-tree-compiler \
    sudo wget curl \
    && apt clean

WORKDIR /src