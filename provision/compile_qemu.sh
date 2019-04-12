#!/bin/bash

cd "${TOP_FOLDER:=~}/qemu-eos/qemu-2.5.0" &&
../configure_eos.sh &&
make -j2
