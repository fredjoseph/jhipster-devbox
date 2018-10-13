Vagrant.configure("2") do |config|
    config.vm.box = "ubuntu/bionic64"
    config.vm.provision :shell, :path => "scripts/setup.sh"
    config.vm.network :forwarded_port, host: 8080, guest: 8080
    config.vm.network :forwarded_port, host: 9000, guest: 9000
    config.ssh.insert_key = true
    config.vm.synced_folder '.', '/vagrant', disabled: true

    config.vm.provider :virtualbox do |vb|
        vb.gui = true
        # Use VBoxManage to customize the VM.
        vb.customize ["modifyvm", :id, "--name", "jhipster-devbox"]
        vb.customize ["modifyvm", :id, "--memory", "15360"]
        vb.customize ["modifyvm", :id, "--cpus", 8]
        vb.customize ["modifyvm", :id, "--vram", 128]
        vb.customize ["modifyvm", :id, "--usb", "on"]
        # vb.customize ["modifyvm", :id, "--usbxhci", "on"]
        # vb.customize ["modifyvm", :id, "--accelerate3d", "on"]
        vb.customize ['modifyvm', :id, '--clipboard', 'bidirectional']
        vb.customize ['modifyvm', :id, '--draganddrop', 'bidirectional']
        # vb.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
        vb.customize ['setextradata', :id, 'GUI/ScaleFactor', '2'] # High DPI screen
        vb.customize ["storageattach", :id, "--storagectl", "SATA Controller", "--port", "0", "--device", "0", "--nonrotational", "on"] # SSD
    end
end
