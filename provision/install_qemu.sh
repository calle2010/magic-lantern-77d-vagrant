#!/bin/bash

if [ ! -d "${TOP_FOLDER:=~}/qemu-eos" ]; then
  echo install qemu-eos in ${TOP_FOLDER}
  cd "${TOP_FOLDER}/magic-lantern"
  hg update qemu -C
  cd contrib/qemu
  yes | ./install.sh
  # patch run_canon_fw.sh so that the monitor socket is not created on vboxsf file system
  cd "${TOP_FOLDER}/qemu-eos"
  patch <"${TOP_FOLDER}/provision/run_canon_fw.patch"
else
 echo qemu-eos is already installed in ${TOP_FOLDER}
fi
