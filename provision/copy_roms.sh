#!/bin/bash

export TARGET=${TOP_FOLDER:=~}/qemu-eos

find /vagrant/ROMs/* -maxdepth 0 -type d -execdir \
  bash -c 'mkdir $TARGET/{}; cp /vagrant/ROMs/{}/ROM?.{BIN,MD5} $TARGET/{}' \;
