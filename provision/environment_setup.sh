#!/bin/bash

if [ ! -e ~vagrant/bin ]; then
  echo setting up home environment for user vagrant
  # link ~vagrant/bin to /vagrant/bin for easier script access
  ln -s /vagrant/bin ~vagrant/bin
else
 echo home environment for user vagrant seems to have been created already
fi
