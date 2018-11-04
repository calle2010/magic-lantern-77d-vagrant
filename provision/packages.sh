#!/bin/bash

echo install packages needed for Magic Lantern development and qemu

apt-get update
sudo apt-get install -y \
    build-essential \
    moreutils \
    colorized-logs \
    flex \
    bison \
    mercurial \
    pkg-config \
    libtool \
    git \
    libglib2.0-dev \
    libpixman-1-dev \
    zlib1g-dev \
    libgtk2.0-dev \
    xz-utils \
    mtools \
    netcat-openbsd \
    python \
    python-pip \
    python-docutils \
    gdb-multiarch \
    gcc-arm-none-eabi \
    libnewlib-arm-none-eabi \
    python-dev \
    xfce4
