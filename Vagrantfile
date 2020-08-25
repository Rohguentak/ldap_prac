Vagrant.configure("2") do |config|
  config.vm.box = "centos/7"
  config.vm.define 'server' do |ser|
    ser.vm.hostname = 'server.local'
    ser.vm.network "private_network", ip: "192.168.12.10"
 end

  config.vm.define 'client1' do |cli|
    cli.vm.hostname = 'client1.local'
    cli.vm.network "private_network", ip: "192.168.12.20"
  end
  
  config.vm.define 'client2' do |cli|
    cli.vm.hostname = 'client2.local'
    cli.vm.network "private_network", ip: "192.168.12.21"
  end

end
