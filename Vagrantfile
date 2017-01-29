# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure(2) do |config|
  config.vm.box = "boxcutter/ubuntu1604"

  config.vm.network "public_network", bridge: "en4", mac: "00:1c:42:e7:b4:3e"

  config.vm.provider :parallels do |v|
    v.name = 'pxe'
    v.memory = '1024'
    v.cpus = 4
  end

  config.vm.provider :virtualbox do |v|
    v.name = 'pxe'
    v.memory = '1024'
    v.cpus = 4
  end

  config.ssh.shell = "bash -c 'BASH_ENV=/etc/profile exec bash'"
  config.vm.provision "shell", path: "provision.sh"
end
