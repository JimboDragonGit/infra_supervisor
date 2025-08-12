#
# Cookbook:: infra_supervisor
# Recipe:: default
#
# Copyright:: 2023, The Authors, All Rights Reserved.

infra_userdata node[cookbook_name]['bootstrapper']['name'] do
  chef_server(
    {
      chef_server_url: node['chefserver']['chef_server_url'],
      options: {
        client_name: node['chefserver']['bootstrapper']['name'],
        signing_key_filename: node['chefserver']['bootstrapper']['key_file'],
      }
    }
  )
  action :install
end
