require 'chef/provisioning'

controller_config = <<-ENDCONFIG
  config.vm.network "forwarded_port", guest: 443, host: 9443 # dashboard-ssl
  config.vm.network "forwarded_port", guest: 4002, host: 4002
  config.vm.network "forwarded_port", guest: 5000, host: 5000
  config.vm.network "forwarded_port", guest: 8773, host: 8773 # compute-ec2-api
  config.vm.network "forwarded_port", guest: 8774, host: 8774 # compute-api
  config.vm.network "forwarded_port", guest: 35357, host: 35357
  config.vm.network "forwarded_port", guest: 6080, host: 6080
  config.vm.provider "virtualbox" do |v|
    v.memory = 2048
    v.cpus = 2
    v.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
    v.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end
  config.omnibus.chef_version="12.2.1"
  config.vm.network "private_network", ip: "10.0.3.11"
  config.vm.network "private_network", ip: "10.0.4.11"
ENDCONFIG

network_config = <<-ENDCONFIG
  config.vm.provider "virtualbox" do |v|
    v.memory = 1024
    v.cpus = 1
    v.customize ["modifyvm", :id, "--nicpromisc2", "allow-all"]
    v.customize ["modifyvm", :id, "--nicpromisc3", "allow-all"]
    v.customize ["modifyvm", :id, "--nicpromisc4", "allow-all"]
    v.customize ["modifyvm", :id, "--natdnshostresolver1", "on"]
  end
  config.omnibus.chef_version="12.2.1"
  config.vm.network "private_network", ip: "10.0.3.21"
  config.vm.network "private_network", ip: "10.0.4.21"
  config.vm.network "private_network", ip: "10.0.5.21"
ENDCONFIG

machine 'controller' do
  add_machine_options vagrant_config: controller_config
  role 'os-compute-single-controller-no-network'
  recipe 'openstack-network::identity_registration'
  # role 'os-network-openvswitch'
  # role 'os-network-dhcp-agent'
  # role 'os-network-metadata-agent'
  recipe 'openstack-network::default'
  role 'os-network-server'
  recipe 'openstack-common::openrc'
  recipe 'openstack-orchestration::identity_registration'
  recipe 'openstack-orchestration::engine'
  recipe 'openstack-orchestration::api'
  chef_environment 'my-multi-neutron'
  file('/etc/chef/openstack_data_bag_secret',
        "#{File.dirname(__FILE__)}/.chef/encrypted_data_bag_secret")
  converge true
end

machine 'network' do
  add_machine_options vagrant_config: network_config
  # recipe 'openstack-network::identity_registration'
  role 'os-network-openvswitch'
  role 'os-network-dhcp-agent'
  role 'os-network-metadata-agent'
  recipe 'openstack-network::l3_agent'
  # role 'os-network-server'
  # recipe 'openstack-common::openrc'
  chef_environment 'my-multi-neutron-for-network'
  file('/etc/chef/openstack_data_bag_secret',
        "#{File.dirname(__FILE__)}/.chef/encrypted_data_bag_secret")
  converge true
end

machine_batch do
  # [%w(compute1 61), %w(compute2 62), %w(compute3 63)].each do |name, ip_suff|
  [%w(compute1 61)].each do |name, ip_suff|
    machine name do
      add_machine_options vagrant_config: <<-ENDCONFIG
config.vm.provider "virtualbox" do |v|
  v.memory = 2048
  v.cpus = 2
end
config.omnibus.chef_version=:latest
config.vm.network "private_network", ip: "10.0.3.#{ip_suff}"
config.vm.network "private_network", ip: "10.0.4.#{ip_suff}"
config.omnibus.chef_version="12.2.1"
ENDCONFIG
      role 'os-compute-worker'
      chef_environment 'my-multi-neutron-for-compute'
      file('/etc/chef/openstack_data_bag_secret',
            "#{File.dirname(__FILE__)}/.chef/encrypted_data_bag_secret")
      converge true
    end
  end
end
