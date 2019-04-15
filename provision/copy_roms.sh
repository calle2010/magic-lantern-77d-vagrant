#!/bin/bash

export TARGET=${TOP_FOLDER:=~}/qemu-eos

find $TOP_FOLDER/ROMs/* -maxdepth 0 -type d -execdir \
  bash -c 'mkdir $TARGET/{}; cp $TOP_FOLDER/ROMs/{}/ROM?.{BIN,MD5} $TARGET/{}' \;
