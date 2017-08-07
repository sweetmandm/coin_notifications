# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.configure("2") do |config|

  config.vm.box = "ubuntu/xenial64"

  config.vm.network "private_network", ip: "192.168.50.8"

  config.vm.provider "virtualbox" do |vb|
    vb.memory = 2048
  end

  config.vm.provision :shell,
    inline: "sudo cp /home/ubuntu/.ssh/authorized_keys /root/.ssh/authorized_keys"

  config.vm.provision :shell,
    inline: "apt-get update && apt-get install python-dev python-pip -q -y"
end
