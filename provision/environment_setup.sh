#!/bin/bash

if [ -e ~vagrant/bin ]; then
  echo home environment for user vagrant seems to have been created already
else
  echo setting up home environment for user vagrant
  # link ~vagrant/bin to $TOP_FOLDER/bin for easier script access
  ln -s $TOP_FOLDER/bin ~vagrant/bin
  # link gdb-multiarch so that it is easier to follow some tutorials
  ln -s /usr/bin/gdb-multiarch ~vagrant/bin/arm-none-eabi-gdb
  # set some aliases
  # source the mtools_setup so that $MSD variable is defined
  cat >.bash_aliases <<ALIASES_END
. $TOP_FOLDER/magic-lantern/contrib/qemu/scripts/mtools_setup.sh
alias sdls="mdir -i $TOP_FOLDER/qemu-eos/\$MSD"
alias sdcp="mcopy -i $TOP_FOLDER/qemu-eos/\$MSD"
alias sdrm="mdel -i $TOP_FOLDER/qemu-eos/\$MSD"
alias edit='/bin/nano'
ALIASES_END
fi
