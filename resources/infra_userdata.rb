# To learn more about Custom Resources, see https://docs.chef.io/custom_resources/
require 'unix_crypt'
require 'securerandom'

provides :infra_userdata

default_action :cycle

property :secretname, String, name_property: true
property :public_secret, String, name_property: true
property :secret, String, default: UnixCrypt::SHA512.build(SecureRandom.base64(12))
property :chef_server, Hash, default: {
                                        chef_server_url: Chef::Config[:chef_server_url],
                                        options: {
                                          client_name: Chef::Config[:client_name],
                                          signing_key_filename: Chef::Config[:signing_key_filename],
                                        }
                                      }
property :userdata, Hash, default: {}

unified_mode true

load_current_value do |current_context|
  begin
    current_user_secret_data_bag = data_bag_item(current_context.public_secret, current_context.secretname)
    current_context.secret = current_user_secret_data_bag['secret']
  rescue Net::HTTPServerException => e
    Chef::Log.warn("Is a 403 error? #{e}")
  rescue e
    puts "Error to fetch data bag: #{e.message}"
  end

  begin
    current_user_data_data_bag = data_bag_item(current_context.secretname, 'user_data')
    current_context.userdata = current_user_data_data_bag.reject {|key, value| key.include?('id')}
  rescue Net::HTTPServerException => e
    Chef::Log.warn("Is a 403 error? #{e}")
  rescue e
    puts "Error to fetch data bag: #{e.message}"
  end
end

action :begin do
  own_data(:prepare)
  set_chef_user
end

action :download do
  own_data_bag(:build)
  own_data_bag_item('secret', {secret: new_resource.secret}, :create)
end

action :verify do
end

action :clean do
end

action :unpack do
end

action :prepare do
end

action :build do
  user_databag(:create)
end

action :check do
end

action :install do
  own_data_bag_item('secret', {secret: new_resource.secret}, :create)
  user_databag(:create)
end

action :strip do
end

action :end do
  own_data_bag_item('secret', {secret: new_resource.secret}, :delete)
  user_databag(:delete)
  own_data_bag(:delete)
end

action :recycle do
  action_end
  action_cycle
end

action :cycle do
  action_begin
  action_download
  action_verify
  action_clean
  action_unpack
  action_prepare
  action_build
  action_check
  action_install
  action_strip
  action_end
end

action_class do
  def secret
    new_resource.secret
  end

  def infra_secret
    data_bag_item(new_resource.public_secret, new_resource.secretname)['secret']
  end

  def user_raw_data
    {id: "user_data"}.merge new_resource.userdata
  end

  def is_updating_secret_itself?
    new_resource.secretname == new_resource.name
  end

  def is_updating_itself?
    is_updating_secret_itself?
  end

  def own_data_bag(action)
    chef_data_bag new_resource.name do
      action action
    end
  end

  def own_data_bag_item(item, data, action)
    own_data_bag(action)
    new_data = {:id => item}.merge(data)
    chef_data_bag_item item do
      chef_server chef_server
      data_bag new_resource.name
      raw_data new_data
      action action
    end
  end

  def user_databag(action = :create)
    Chef::Log.warn("Encrypt user data bag of #{new_resource.name} with key #{new_resource.secret}")
    begin
      chef_data_bag_item 'user_data' do
        chef_server chef_server
        complete false
        data_bag new_resource.name
        encryption_version Chef::Config[:data_bag_encrypt_version].nil? ? 3 : Chef::Config[:data_bag_encrypt_version]
        secret new_resource.secret
        encrypt true
        old_secret infra_secret
        raw_data user_raw_data
        action action
      end
    rescue Net::HTTPServerException => e
      Chef::Log.warn("Is a 403 error? #{e}")
    end
  end
end
