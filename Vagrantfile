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
  config.vm.provision "packages", type: "shell" do |s|
    s.path = "provision/packages.sh"
    s.privileged = true
  end

  config.vm.provision :reload

  # the location of the /vagrant folder in the guest
  vagrantFolder = "/vagrant"

  config.vm.provision "clone_ml", type: "shell" do |s|
    s.path = "provision/clone_ml.sh"
    s.privileged = false
    s.env = { "TOP_FOLDER" => vagrantFolder }
  end

  config.vm.provision "environment_setup", type: "shell" do |s|
    s.path = "provision/environment_setup.sh"
    s.privileged = false
  end

  config.vm.provision "install_qemu", type: "shell" do |s|
    s.path = "provision/install_qemu.sh"
    s.privileged = false
    s.env = { "TOP_FOLDER" => vagrantFolder }
  end

  config.vm.provision "compile_qemu_77D", type: "shell" do |s|
    s.path = "provision/compile_qemu_77D.sh"
    s.privileged = false
    s.env = { "TOP_FOLDER" => vagrantFolder }
  end

end
