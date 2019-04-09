# Purpose

Create a build and test environment for Magic Lantern 77D development in one step.

# Directory structure

```
VagrantFile
|
|- ROMs/ # put your firmware ROM files here before provisioning
|
|- provision/ # scripts to setup the guest Vagrant machine
|
|- magic-lantern/ # cloned ML repository, will be created by provisioning
|
|- qemu-eos/ # QEMU installation, will be created by provisioning
|
|- bin/ # useful executables like disassemblev7.pl
|
```

Note that while qemu-eos is visible in the file system of the host machine it is not
executable in the host environment, unless the operating system and architecture are
identical!

# Vagrant Plugin Configuration

To install the VirtualBox guest additions automatically in the Vagrant machine.
The second plugin allows a reload during provisioning of the Vagrant machine.

```
$ vagrant plugin install vagrant-vbguest
$ vagrant plugin install vagrant-reload
```

# Provisioning of the Vagrant machine

First copy your ROM files to ROMs directory.

Next execute ```vagrant up```
This will take some time to complete the provisioning:
- download Ubuntu box
- start Ubuntu
- download and install needed packages
- clone the ML repository
- install QEMU
- copy ROM files
- compile QEMU

# Using the Vagrant machine

After the provisioning has been completed:
- login to GUI with vagrant / vagrant
- on first start you should configure your keyboard layout

```sudo dpkg-reconfigure keyboard-configuration```

- also you should consider to set the correct timezone

```sudo dpkg-reconfigure tzdata```

- a system restart may be required for this to take effect in X11: ```vagrant reload```

- execute ```startx``` to start the Xfce4 desktop
- run a terminal
- start QEMU from the terminal to be able to see graphical output

```./run_canon_fw.sh 77D,firmware="boot=0"```

# Compile and run Magic Lantern

To avoid issues with modules in the Makefile at least one must be build. For this

```
$ cd /vagrant/magic-lantern/platform/5D3.113
$ make clean && make zip ML_MODULES=arkanoid
```

Then compile and install to Qemu SD card the minimal-d78:

```
$ cd /vagrant/magic-lantern/platform/77D.102/
$ make clean; make install_qemu CONFIG_QEMU=y ML_MODULES=
```

Then run it in Qemu

```
$ cd /vagrant/qemu-eor
$ ./run_canon_fw.sh 77D,firmware="boot=1" -s -S & gdb-multiarch -x 77D/patches.gdb
```

# Tipps

For VirtualBox in MacOs the the host key is the right Cmd key. Press it to realease
the focus from the guest window.

For QEMU in X11 press Ctrl+Alt+G to release the focus from the ML window.

You can login to the command line with ```vagrant ssh```.
