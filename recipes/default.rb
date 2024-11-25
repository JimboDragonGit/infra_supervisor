#
# Cookbook:: infra_supervisor
# Recipe:: default
#
# Copyright:: 2023, The Authors, All Rights Reserved.

infra_userdata node[cookbook_name]['bootstrappeur'] do
  action :install
end
