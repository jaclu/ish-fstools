#
# Dependencies:
# vagrant plugin install faraday vagrant-cachier
#

VAGRANTFILE_API_VERSION = "2"

alpine_mirror = "dl-cdn.alpinelinux.org"
debian_mirror = "deb.debian.org"

base_dir = File.expand_path(File.dirname(__FILE__))
cluster = {
  #
  #  Remember to update ansible/inventory.ini to match this hostlist
  #  for provisioning to work
  #

  "v-alp318-1" =>  { :ip => "192.168.60.51", :box => "generic/alpine318", :cpus => 1, :mem => 256 },
  #"v-alp318-2" =>  { :ip => "192.168.60.52", :box => "generic/alpine316", :cpus => 1, :mem => 256 },

  "v-deb10-1" =>  { :ip => "192.168.60.71", :box => "geerlingguy/debian10", :cpus => 1, :mem => 384 },

  # Fails to set hostname...
  # "v-devu4-1" =>  { :ip => "192.168.60.61", :box => "generic/devuan4", :cpus => 1, :mem => 256 },
}

Vagrant.configure(VAGRANTFILE_API_VERSION) do |config|

  if Vagrant.has_plugin?("vagrant-cachier")
    config.cache.scope = :machine
    config.cache.enable :apt
  end

  config.ssh.insert_key = false
  config.ssh.extra_args = ['-o', 'StrictHostKeyChecking=no', '-o', 'UserKnownHostsFile=/dev/null']

  ssh_pub_key_path = "#{Dir.home}/.ssh/id_rsa.pub"
  if File.exist?(ssh_pub_key_path)
    ssh_pub_key = File.readlines(ssh_pub_key_path).first.strip
    config.vm.provision 'shell',
      inline: "echo '#{ssh_pub_key}' >> /home/vagrant/.ssh/authorized_keys",
      privileged: false
  end

  # Re-enable the shared folder feature
  config.vm.synced_folder '.', '/vagrant', SharedFoldersEnableSymlinksCreate: false, disabled: true

  cluster.each_with_index do |(hostname, info), _index|
    config.vm.define hostname do |cfg|

      cfg.vm.provider :virtualbox do |vb, override|
        override.vm.box = info[:box]
        override.vm.network :private_network, ip: info[:ip]
        override.vm.hostname = hostname

        vb.name = hostname
        vb.customize ['modifyvm', :id, '--memory', info[:mem], '--cpus', info[:cpus], '--hwvirtex', 'on']
      end

      # Define pre-ansible provisioning steps for different OSes
      if info[:box].include?('alpine')
        cfg.vm.provision 'Pre-Ansible - Alpine: Ensure Python3 is installed',
                         type: 'shell',
                         privileged: true,
                         inline: <<-SHELL

        if [ -f /etc/alpine-release ]; then
            if command -v python3 > /dev/null; then
                echo "Python3 installed"
            else
                apk add python3
            fi

          # Using alpine_mirror repository
          old_mirror="$(grep main /etc/apk/repositories | sed 's#//#|#' | \
              sed 's#/alpine/#|#' | cut -d'|' -f 2)"
          sed -i "s/$old_mirror/#{alpine_mirror}/" /etc/apk/repositories
          echo "Using mirror: [#{alpine_mirror}]"

        else
             echo "Not Alpine"
        fi

        SHELL
      elsif info[:box].include?('debian')
        cfg.vm.provision 'Pre-Ansible - Debian 10: hold grub-pc',
                         type: 'shell',
                         privileged: true,
                         inline: <<-SHELL

        if grep -q "10." /etc/debian_version 2> /dev/null; then
            apt-mark hold grub-pc
        else
            echo "Not Debian 10 - nothing put on hold"
        fi

        # Using deb.debian.org repository
        org_repo="$(grep main /etc/apt/sources.list | grep 'deb ' | \ 
            grep -v '^#' | head -1 | sed 's#//#|#' | \
            sed 's#/#|#' | cut -d'|' -f 2)" 
 
        sed -i "s/$org_repo/#{debian_mirror}/" /etc/apt/sources.list
        echo "Replaced source $org_repo with #{debian_mirror}"

        sed -i 's/^deb-src/# deb-src/' /etc/apt/sources.list
        echo "Disabled deb-src lines"

        SHELL
      end

      # Uncomment and update the Ansible provisioning section if needed
      # if index == cluster.size - 1
      #   cfg.vm.provision :ansible do |ansible|
      #     ansible.compatibility_mode = '2.0'
      #     #ansible.verbose = 'vvvv'
      #     ansible.inventory_path = 'ansible/hosts.ini'
      #     ansible.playbook = 'ansible/provisioning.yml'
      #     ansible.limit = "#{info[:hostname]}"
      #   end
      # end
      
    end
  end
end
