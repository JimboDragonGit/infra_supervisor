#
# Cookbook:: infra_supervisor
# Recipe:: default
#
# Copyright:: 2023, The Authors, All Rights Reserved.

begin
  fetched_secret = data_bag_item(node['chefserver']['secretdatabag'], node['chefserver']['secretdatabagitem'])[node['chefserver']['secretdatabagkey']]
rescue Net::HTTPServerException => e
  Chef::Log.warn("Could not load secret from data bag #{node['chefserver']['secretdatabag']}/#{node['chefserver']['secretdatabagitem']}: #{e.message}")
  fetched_secret = nil
rescue Net::HTTPClientException => e
  Chef::Log.warn("Data Bag HTTP Client Error: #{e}")
  fetched_secret = nil
rescue => e
  Chef::Log.warn "Error to fetch data bag user_secret_data: #{e.class}"
  Chef::Log.warn "Error to fetch data bag user_secret_data: #{e.message}"
  fetched_secret = nil
end

infra_userdata node['chefserver']['bootstrapper']['name'] do
  chef_server(
    {
      chef_server_url: node['chefserver']['chef_server_url'],
      options: {
        client_name: node['chefserver']['bootstrapper']['name'],
        signing_key_filename: node['chefserver']['bootstrapper']['key_file'],
      }
    }
  )
  secret fetched_secret unless fetched_secret.nil?
  action :install
end
