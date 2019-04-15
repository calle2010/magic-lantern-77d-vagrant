# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  # VirtualBox creates shared /vagrant folder by default
  vagrantFolder = "/vagrant"

  config.vm.provider "virtualbox" do |vbox,override|
    override.vm.box = "ubuntu/bionic64"
    override.vagrant.plugins = ["vagrant-vbguest", "vagrant-reload"]
    vbox.gui = true
    vbox.name = "ML Build Environment"
    vbox.memory = 4096
    vbox.cpus = 2
  end

  # for easier usage with Hyper-V set environment variable
  # in Windows configuration:
  # VAGRANT_DEFAULT_PROVIDER=hyperv

  config.vm.provider "hyperv" do |hv,override|
    override.vm.box = "generic/ubuntu1804"
    override.vagrant.plugins = ["vagrant-reload"]
    hv.vmname = "ML Build Environment"
    hv.memory = 1024
    hv.maxmemory = 4096
    hv.cpus = 2
    hv.auto_stop_action= "Save"
    override.vm.synced_folder ".", "/vagrant", type: "smb"
  end

  # for hg serve
  config.vm.network "forwarded_port", guest: 8000, host: 8000

  # install packages that install.sh would install for Ubuntu and ARM compiler option 1
  config.vm.provision "packages", type: "shell" do |s|
    s.path = "provision/packages.sh"
    s.privileged = true
  end

  config.vm.provision :reload

  # general user environment setup

  config.vm.provision "configure_hg", type: "shell" do |s|
    s.path = "provision/configure_hg.sh"
    s.privileged = true
  end

  config.vm.provision "environment_setup", type: "shell" do |s|
    s.path = "provision/environment_setup.sh"
    s.privileged = false
    s.env = { "TOP_FOLDER" => vagrantFolder }
  end

  # provisioning steps to setup Qemu
  # the scripts below can be used also to install
  # ML and qemu to the home directory of the vagrant user

  config.vm.provision "clone_ml", type: "shell" do |s|
    s.path = "provision/clone_ml.sh"
    s.privileged = false
    s.env = { "TOP_FOLDER" => vagrantFolder }
  end

  config.vm.provision "install_qemu", type: "shell" do |s|
    s.path = "provision/install_qemu.sh"
    s.privileged = false
    s.env = { "TOP_FOLDER" => vagrantFolder }
  end

  config.vm.provision "copy_roms", type: "shell" do |s|
    s.path = "provision/copy_roms.sh"
    s.privileged = false
    s.env = { "TOP_FOLDER" => vagrantFolder }
  end

  config.vm.provision "compile_qemu", type: "shell" do |s|
    s.path = "provision/compile_qemu.sh"
    s.privileged = false
    s.env = { "TOP_FOLDER" => vagrantFolder }
  end

end
