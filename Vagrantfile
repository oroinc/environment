# -*- mode: ruby -*-
# vi: set ft=ruby :

Vagrant.require_version ">= 1.9"

vmIp = "192.168.50.50"
memory = ( ENV['MEMORY'] || 4096 ).to_i
cpus = ( ENV['CPUS'] || 2 ).to_i

scriptEnableSwap = <<SCRIPT
  if grep -q "swapfile" /etc/fstab; then
    echo 'swapfile found. No changes made.'
  else
    echo 'swapfile not found. Adding swapfile.'
    fallocate -l 2001M /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    echo '/swapfile none swap defaults 0 0' >> /etc/fstab
  fi
SCRIPT

scriptInstallBaseSystem = <<SCRIPT
  apt-get install -y mc vim htop ctop git curl resolvconf dnsutils
  curl -s -L https://get.docker.com | bash
  curl -s -L https://github.com/docker/compose/releases/download/1.11.1/docker-compose-`uname -s`-`uname -m` > /usr/local/bin/docker-compose
  chmod +x /usr/local/bin/docker-compose
  usermod -aG docker vagrant
  echo 1 > /proc/sys/net/ipv4/ip_forward
  echo '#!/bin/sh -e' > /etc/rc.local
  echo 'iptables -A FORWARD -j ACCEPT' | tee -a /etc/rc.local | sh
  echo 'exit 0' >> /etc/rc.local
SCRIPT

scriptInstallDockerDns = <<SCRIPT
  docker run --restart always -d --name dns-gen --dns=8.8.8.8 --dns=8.8.4.4 -p #{vmIp}:53:53/udp -v /var/run/docker.sock:/var/run/docker.sock oroinc/docker-dns-gen
  echo "nameserver #{vmIp}" | tee -a /etc/resolvconf/resolv.conf.d/head
  resolvconf -u
SCRIPT

scriptSetupUserEnvironment = <<SCRIPT
    sudo -u vagrant ssh-keygen -t rsa -f /home/vagrant/.ssh/id_rsa -P ""
SCRIPT

Vagrant.configure(2) do |config|
    config.vm.hostname = "oroenv"
    config.vm.provider :virtualbox do |vb, override|
        override.vm.box = "bento/ubuntu-16.04" # See for more info https://github.com/chef/bento
        vb.gui = false
        vb.memory = memory
        vb.cpus = cpus
        
        override.vm.network "private_network", ip: vmIp
        # Use faster paravirtualized networking
        # vb.customize ["modifyvm", :id, "--nictype1", "virtio"]
        # vb.customize ["modifyvm", :id, "--nictype2", "virtio"]
    end
    # avoid possible request "vagrant@127.0.0.1's password:" when "up" and "ssh"
    config.ssh.password = "vagrant"
    config.vm.provision :shell, :inline => scriptEnableSwap
    config.vm.provision :shell, :inline => scriptInstallBaseSystem
    config.vm.provision :shell, :inline => scriptInstallDockerDns
    config.vm.provision :shell, :inline => scriptSetupUserEnvironment
end

# HOW TO ADD ROUTE TO DOCKER THROUGH VAGRANT VM

# Windows
# route -p ADD 172.0.0.0 MASK 255.0.0.0 192.168.50.50

# OSX
# sudo route -n add -net 172.0.0.0/8  192.168.50.50

# Linux
# sudo route add -net 172.0.0.0/8 gw 192.168.50.50
