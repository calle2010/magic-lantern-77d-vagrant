#!/bin/bash

echo install packages needed for Magic Lantern development and qemu

apt-get update
sudo apt-get install -y \
    bison \
    build-essential \
    colorized-logs \
    flex \
    gcc-arm-none-eabi \
    gdb-multiarch \
    git \
    libglib2.0-dev \
    libgtk2.0-dev \
    libnewlib-arm-none-eabi \
    libpixman-1-dev \
    libtool \
    mercurial \
    moreutils \
    mtools \
    netcat-openbsd \
    pkg-config \
    python \
    python-dev \
    python-docutils \
    python-pip \
    python3-termcolor \
    tortoisehg \
    xfce4 \
    xz-utils \
    zip \
    zlib1g-dev
