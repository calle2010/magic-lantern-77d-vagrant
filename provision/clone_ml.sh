#!/bin/bash

if [ ! -d "${TOP_FOLDER:=~}/magic-lantern" ]; then
  echo cloning Magic Lantern in ${TOP_FOLDER}
  cd ${TOP_FOLDER}
  hg clone https://bitbucket.org/hudson/magic-lantern
else
  echo Magic Lantern repository is already cloned in ${TOP_FOLDER}
fi
