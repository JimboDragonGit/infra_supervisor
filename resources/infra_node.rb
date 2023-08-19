# To learn more about Custom Resources, see https://docs.chef.io/custom_resources/

provides :infra_node

default_action :cycle

property :secretname, String, default: ''

property :live_stream, [TrueClass, FalseClass], default: false

unified_mode true

action :prepare_supervisor do
end

action :prepare_node do
end

action :delete do
end

action :prepare do
  chef_gem 'unix-crypt'
  chef_gem 'ruby-shadow'
  chef_gem 'securerandom'

  require 'unix_crypt'
  require 'shadow'
  require 'securerandom'

  ssh_known_hosts_entry 'localhost'
  ssh_known_hosts_entry '127.0.0.1'
  ssh_known_hosts_entry node['ipaddress']
  ssh_known_hosts_entry node['fqdn']
  ssh_known_hosts_entry 'github.com'

  chef_gem 'cheffish' do
    action :install
    compile_time true
  end

  cookbook_file ::File.join("/etc", "hosts") do
    source ::File.join("etc", "hosts")
    mode '0400'
  end

  cookbook_file ::File.join("/etc", "chef", 'validation.pem') do
    source ::File.join("certs", 'chef', 'ypgroup-validator.pem')
    mode '0400'
    action :delete
  end

  cron_d "chef_client_supervisor_workstation" do
    command               'check_YP'
    comment               'Run chef client periodicaly'
    day                   '*'
    hour                  '*'
    minute                '0'
    month                 '*'
    weekday               '*'
  end

  Chef::Log.debug("Setting YP Node with parameter #{JSON.pretty_generate(Chef::Config.knife[:userdata])}")

  template ::File.join('/etc', 'chef', 'infra_env.rb') do
    source 'infra_env.rb.erb'
    variables userdata: Chef::Config.knife[:userdata]
  end

  template ::File.join('/etc', 'chef', 'client.rb') do
    source 'knife.rb.erb'
    variables userdata: Chef::Config.knife[:userdata]
  end
end

action :install do
end

action :build do
end

action :clean do
end

action :release do
end

action :cycle do
  # action_clean
  action_prepare
  action_build
  action_install
  # action_test
  # action_release
end

action :recycle do
  action_delete
  action_cycle
end

action_class do
end
