#!/bin/bash

# This script must run as root

mkdir -p /etc/mercurial/hgrc.d/
cat >/etc/mercurial/hgrc.d/vagrant.rc <<ENDHGRC
[extensions]
rebase =
shelve =
strip =
ENDHGRC
