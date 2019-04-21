# encoding: utf-8

require 'time'
offset = ((Time.zone_offset(Time.now.zone) / 60) / 60)
timezone_suffix = offset >= 0 ? "-#{offset.to_s}" : "+#{offset.to_s}"
timezone = "Etc/GMT" + timezone_suffix

require 'yaml'
vagrant_config = {
  'name' => "jhipster-devbox",
  'cpus' => 1,
  'ram' => "4096",
  'vram' => "64",
  'accelerate3d' => "on",
  'scale_factor' => "1",
  'ssd' => "off",
  'ports' => [
    {
      'host' => 8080,
      'guest' => 8080
    },
    {
      'host' => 9000,
      'guest' => 9000
    }
  ],
  'keyboard_layout' => "us",
  'keyboard_variant' => "",
  'locale' => "en_US",
  'timezone' => timezone
}

current_dir    = File.dirname(File.expand_path(__FILE__))
configs        = YAML.load_file("#{current_dir}/Vagrantfile.local")
override_vagrant_config = configs['configs'][configs['configs']['use']]

vagrant_config.merge!(override_vagrant_config)
    
Vagrant.configure('2') do |config|
    config.vm.box = 'bento/ubuntu-18.04'
    vagrant_config['ports'].each { |obj|
        config.vm.network :forwarded_port, host: obj['host'], guest: obj['guest']
    }
    config.ssh.insert_key = true
    config.vm.synced_folder Dir.home(), '/host', disabled: false
    
    config.vm.provision :shell, :inline => "sudo rm /etc/localtime && sudo ln -s /usr/share/zoneinfo/" + vagrant_config['timezone'] + " /etc/localtime", run: 'always'
    config.vm.provision :shell, env: vagrant_config, :path => 'scripts/setup.sh'
    
    config.vm.provider :virtualbox do |vb|
        vb.gui = true
        # Use VBoxManage to customize the VM.
        vb.customize ['modifyvm', :id, '--name', vagrant_config['name']]
        vb.customize ['modifyvm', :id, '--cpus', vagrant_config['cpus']]
        vb.customize ['modifyvm', :id, '--memory', vagrant_config['ram']]
        vb.customize ['modifyvm', :id, '--vram', vagrant_config['vram']]
        vb.customize ['modifyvm', :id, '--accelerate3d', vagrant_config['accelerate3d']]
        vb.customize ['modifyvm', :id, '--clipboard', 'bidirectional']
        vb.customize ['modifyvm', :id, '--draganddrop', 'bidirectional']
        vb.customize ['modifyvm', :id, '--natdnshostresolver1', 'on']
        #vb.customize ['modifyvm', :id, '--natdnsproxy1', 'on']
        vb.customize ['modifyvm', :id, '--usb', 'on']
        vb.customize ['setextradata', :id, 'GUI/ScaleFactor', vagrant_config['scale_factor']]
        vb.customize ['setextradata', 'global', 'GUI/SuppressMessages', 'all' ]
        vb.customize ['storageattach', :id, '--storagectl', 'SATA Controller', '--port', '0', '--device', '0', '--nonrotational', vagrant_config['ssd']]
        # set timesync parameters to keep the clock in sync
        # sync time every 10 seconds
        vb.customize [ 'guestproperty', 'set', :id, '/VirtualBox/GuestAdd/VBoxService/--timesync-interval', 10000 ]
        # adjustments if drift > 100 ms
        vb.customize [ 'guestproperty', 'set', :id, '/VirtualBox/GuestAdd/VBoxService/--timesync-min-adjust', 100 ]
        # sync time on restore
        vb.customize [ 'guestproperty', 'set', :id, '/VirtualBox/GuestAdd/VBoxService/--timesync-set-on-restore', 1 ]
        # sync time on start
        vb.customize [ 'guestproperty', 'set', :id, '/VirtualBox/GuestAdd/VBoxService/--timesync-set-start', 1 ]
        # at 1 second drift, the time will be set and not 'smoothly' adjusted
        vb.customize [ 'guestproperty', 'set', :id, '/VirtualBox/GuestAdd/VBoxService/--timesync-set-threshold', 1000 ]
    end
end
