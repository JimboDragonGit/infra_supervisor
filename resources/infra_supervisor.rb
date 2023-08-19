# To learn more about Custom Resources, see https://docs.chef.io/custom_resources/

provides :supervisor

property :vm_name, String, default: ''
property :live_stream, [TrueClass, FalseClass], default: false
property :cookbooks, Array, default: []
# property :chef_client_file, [RubyType], default: 'value'

default_action :infra_connect

unified_mode true

action :infra_connect do
  action_connect_as_supervisor
  # Chef::Log.warn("Chef::Config = #{Chef::Config.inspect}")
  # include_recipe 'infra_sys'
end

action :connect_as_supervisor do
  chef_data_bag 'public_secret' do
    action :create
  end

  begin
    data_bag_item('public_secret', new_resource.name)
  rescue Exception => e
    chef_data_bag_item new_resource.name do
      data_bag 'public_secret'
      raw_data(
        {
          id: new_resource.name,
          secret: Chef::Config.knife[:userdata][:infra_secret]
        }
      )
      action :create
    end
  ensure
    public_secret = data_bag_item('public_secret', new_resource.name)
  end

  infra_node new_resource.name do
    live_stream new_resource.live_stream
    action :prepare
  end
end

action :deploy_administrators do
  infra_administrator new_resource.name do
    live_stream new_resource.live_stream
    secretname new_resource.name
    action [:prepare, :install]
  end
end

action :deploy_infra_users do
  action_connect_as_supervisor
  infra_users 'Deploy YP Users' do
    live_stream new_resource.live_stream
  end
end

action :deploy_cookbooks do
  action_connect_as_supervisor
  new_resource.cookbooks.each do |cookbook|
    cookbook_deployer cookbook do
      live_stream new_resource.live_stream
      gitproject = case cookbook
      when 'infra_teamcity'
        'devops'
      else
        'ypg-cookbooks'
      end
      git "ssh://git@git.ypg.com:7999/#{gitproject}/#{cookbook}.git"
    end
  end
end

action :deploy_devops_service do
  action_connect_as_supervisor
  devops_agents new_resource.name do
    live_stream new_resource.live_stream
    # action [:prepare, :install]
    action [:clean]
  end
end

action :deploy_chef_service do
  action_connect_as_supervisor
  chef_service new_resource.name do
    live_stream new_resource.live_stream
    action [:prepare, :install]
  end
end

action :deploy_vm do
  action_connect_as_supervisor
  disaster_recovery new_resource.name do
    live_stream new_resource.live_stream
    vm_name new_resource.vm_name
    action [:prepare, :install]
  end
end

action :deploy_f5_server do
  action_connect_as_supervisor
end

action :deploy_database_service do
  action_connect_as_supervisor
end

action :deploy_artifactory_service do
  action_connect_as_supervisor
  artifactory_server new_resource.name do
    live_stream new_resource.live_stream
    action [:prepare, :install]
  end
end

action :deploy_elk_service do
  action_connect_as_supervisor
  elk_service new_resource.name do
    live_stream new_resource.live_stream
    action [:prepare, :install]
  end
end

action :deploy_proxy_service do
  action_connect_as_supervisor
  web_proxy_server new_resource.name do
    live_stream new_resource.live_stream
    action [:prepare, :install]
  end
end

action :deploy_zabbix_service do
  action_connect_as_supervisor
  # zabbix_database new_resource.name do
  #   action [:prepare, :install]
  # end
  # zabbix_server new_resource.name do
  #   action [:prepare, :install]
  # end
  # zabbix_frontend new_resource.name do
  #   action [:prepare, :install]
  # end
  # zabbix_proxies new_resource.name do
  #   action [:prepare, :install]
  # end
end

action :deploy_teamcity_server do
  action_connect_as_supervisor
  teamcity_server new_resource.name do
    live_stream new_resource.live_stream
    action [:prepare, :install]
  end
end

action :deploy_teamcity_agents do
  action_connect_as_supervisor
  teamcity_agents new_resource.name do
    live_stream new_resource.live_stream
    action [:prepare, :install]
  end
end

action :deploy_esb_service do
  action_connect_as_supervisor
end

action :deploy_linko_service do
  action_connect_as_supervisor
end

action :deploy_infra_workstations do
  action_connect_as_supervisor
  infra_workstations new_resource.name do
    live_stream new_resource.live_stream
  end
end

action_class do
end
