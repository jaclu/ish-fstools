Vagrant.configure("2") do |config|
  # Name your container
  config.vm.define "debian10"

  # Use docker provider
  config.vm.provider "docker" do |d|
    d.image = "debian:10"
    d.has_ssh = true   # ensures vagrant can connect via SSH
  end

  # Make sure Vagrant provisions via SSH
  config.vm.provision "shell", inline: <<-SHELL
    apt-get update -y
    apt-get install -y systemd systemd-sysv sudo
  SHELL
end
