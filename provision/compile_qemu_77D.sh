#!/bin/bash

cp "${TOP_FOLDER:=~}"/ROMs/ROM?.{BIN,MD5} \
   "${TOP_FOLDER}/qemu-eos/77D/" &&
cd "${TOP_FOLDER}/qemu-eos/qemu-2.5.0" &&
../configure_eos.sh &&
make -j2
