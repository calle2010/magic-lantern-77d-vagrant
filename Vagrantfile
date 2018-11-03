# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|
  
  config.vagrant.plugins = ["vagrant-vbguest", "vagrant-reload"]

  config.vm.box = "ubuntu/xenial64"

  config.vm.provider "virtualbox" do |v|
    v.gui = true
    v.name = "Magic Lantern Build Environment"
    v.memory = 4096
    v.cpus = 2
  end

 # install packages that install.sh would install for Ubuntu and ARM compiler option 1
  config.vm.provision "shell" do |s|
    s.name = "packages"
    s.path = "provision/packages.sh"
    s.privileged = true
  end

  config.vm.provision :reload

  # the location of the /vagrant folder in the guest
  vagrantFolder = "/vagrant"

  config.vm.provision "shell" do |s|
    s.name = "clone_ml"
    s.path = "provision/clone_ml.sh"
    s.privileged = false
    s.env = { "TOP_FOLDER" => vagrantFolder }
  end

  config.vm.provision "shell" do |s|
    s.name = "environment_setup"
    s.path = "provision/environment_setup.sh"
    s.privileged = false
  end

  config.vm.provision "shell" do |s|
    s.name = "install_qemu"
    s.path = "provision/install_qemu.sh"
    s.privileged = false
    s.env = { "TOP_FOLDER" => vagrantFolder }
  end

  config.vm.provision "shell" do |s|
    s.name = "compile_qemu_77D"
    s.path = "provision/compile_qemu_77D.sh"
    s.privileged = false
    s.env = { "TOP_FOLDER" => vagrantFolder }
  end

end
