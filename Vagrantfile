# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/xenial64"

  config.vm.network "private_network", ip: "192.168.50.8"

  config.vm.provision :shell,
    inline: "apt-get update && apt-get install python-dev python-pip -q -y"
end
