#
# Cookbook:: infra_supervisor
# Recipe:: default
#
# Copyright:: 2023, The Authors, All Rights Reserved.

infra_userdata node[cookbook_name]['bootstrappeur'] do
  chef_server_url(
    {
      chef_server_url: node['chefserver']['chef_server_url'],
      options: {
        client_name: node[cookbook_name]['bootstrappeur'],
        signing_key_filename: node[cookbook_name]['bootstrappeur_key'],
      }
    }
  )
  action :install
end
