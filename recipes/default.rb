#
# Cookbook:: infra_supervisor
# Recipe:: default
#
# Copyright:: 2023, The Authors, All Rights Reserved.

chef_data_bag 'public_secret'

infra_userdata node[cookbook_name]['bootstrappeur'] do
  action :install
end
