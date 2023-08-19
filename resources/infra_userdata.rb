# To learn more about Custom Resources, see https://docs.chef.io/custom_resources/
require 'unix_crypt'
require 'securerandom'

provides :infra_userdata

default_action :cycle

property :secret, String, default: UnixCrypt::SHA512.build(SecureRandom.base64(12))
property :secretname, String, default: ''
property :userdata, Hash, default: {}
property :owner, String, default: ''

unified_mode true

action :delete do
  own_data_bag_item('secret', {secret: new_resource.secret}, :delete)
  user_databag(delete)
  own_data_bag(:delete)
end

action :prepare do
  own_data_bag(:create)
  own_data_bag_item('secret', {secret: new_resource.secret}, :create)
  user_databag(:create)
end

action :install do
end

action :build do
  user_databag(:create)
end

action :clean do
  action_delete
end

action :release do
end

action :test do

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
  def secret
    new_resource.secret
  end

  def infra_secret
    data_bag_item('public_secret', new_resource.secretname)['secret']
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
      data_bag new_resource.name
      raw_data new_data
      action action
    end
  end

  def user_databag(action = :create)
    Chef::Log.warn("Encrypt user data bag of #{new_resource.name} with key #{new_resource.secret}")
    chef_data_bag_item 'user_data' do
      complete false
      data_bag new_resource.name
      encryption_version Chef::Config[:data_bag_encrypt_version].nil? ? 3 : Chef::Config[:data_bag_encrypt_version]
      secret new_resource.secret
      encrypt true
      old_secret infra_secret
      raw_data user_raw_data
      action action
    end
  end
end
