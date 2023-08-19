# To learn more about Custom Resources, see https://docs.chef.io/custom_resources/

provides :infra_administrator

default_action :cycle

property :secretname, String, default: ''

property :live_stream, [TrueClass, FalseClass], default: false

unified_mode true

action :delete do
  infra_chefuser(:delete)
end

action :prepare do
  chef_data_bag new_resource.name do
    action :create
  end

  begin
    public_secret = data_bag('public_secret')
    little_secret = data_bag_item('public_secret', new_resource.name, Chef::Config.knife[:userdata][:infra_secret])
    patate_data = data_bag_item('patate', 'user_data', data_bag_item('public_secret', new_resource.name)[:secret])

    secret_data_bag = data_bag_item(new_resource.name, 'secret', Chef::Config.knife[:userdata][:infra_secret])
    secret_own_data_bag = data_bag_item(new_resource.name, new_resource.name, Chef::Config.knife[:userdata][:infra_secret])

    secret_data_bag = data_bag_item(new_resource.name, 'secret', Chef::Config.knife[:userdata][:infra_secret])
    secret_own_data_bag = data_bag_item(new_resource.name, new_resource.name, Chef::Config.knife[:userdata][:infra_secret])
  rescue Exception => e
    Chef::Log.warn("Failing to fetch data_bag\nRegenerating user_data bag for #{new_resource.name}\nMESSAGE ERROR: #{e}\nsecret_data_bag = #{secret_data_bag}\nsecret_own_data_bag = #{secret_own_data_bag}\npublic_secret = #{public_secret}\nlittle_secret = #{little_secret}\npatate_data = #{patate_data}\nsecret_data_bag = #{secret_data_bag}\nsecret_own_data_bag = #{secret_own_data_bag}\n")

    chef_data_bag_item 'secret' do
      data_bag new_resource.name
      # encryption_version Chef::Config[:data_bag_encrypt_version].nil? ? 3 : Chef::Config[:data_bag_encrypt_version]
      # secret Chef::Config.knife[:userdata][:infra_secret]
      # old_secret Chef::Config.knife[:userdata][:infra_secret]
      # encrypt true
      raw_data({id: 'secret'}.merge(Chef::Config.knife[:userdata]))
      action :create
    end

    # secret_databag_data = Hash.new({id: new_resource.name, data_bag_encrypt_version: 3})
    # secret_databag_data = secret_databag_data.merge!(Chef::Config.knife[:userdata])
    # secret_databag_data.each do |key, value|
    #   Chef::Log.warn("Checking user data #{key} as value #{value}")
    #   if key == :id || key == 'id'
    #     Chef::Log.warn("No need to encrypt #{key} as value #{value}")
    #   else
    #     Chef::Log.warn("Encrypt #{key} as value #{value}")
    #     encrypt_value = UnixCrypt::SHA512.build(value)
    #     secret_databag_data = secret_databag_data.merge!({"#{key}": encrypt_value})
    #     Chef::Log.warn("New #{key} value #{encrypt_value}")
    #   end
    # end
    secret_databag_data = {id: new_resource.name}.merge(Chef::Config.knife[:userdata])
    Chef::Log.warn("Encrypt data bag #{new_resource.name} version #{Chef::Config[:data_bag_encrypt_version]} for item #{new_resource.name} with parameter #{secret_databag_data}")
    [:delete, :create].each do |action|
      chef_data_bag_item new_resource.name do
        data_bag new_resource.name
        encryption_version Chef::Config[:data_bag_encrypt_version].nil? ? 3 : Chef::Config[:data_bag_encrypt_version]
        secret Chef::Config.knife[:userdata][:infra_secret]
        old_secret data_bag_item('public_secret', new_resource.name)[:secret]
        encrypt true
        raw_data secret_databag_data
        action action
      end
    end
    Chef::Log.warn("Sleep a little after data bag encryption")
    sleep 90
  ensure
    public_secret = data_bag('public_secret')
    Chef::Log.warn "public_secret = #{public_secret}"
    little_secret = data_bag_item('public_secret', new_resource.name, Chef::Config.knife[:userdata][:infra_secret])
    Chef::Log.warn "little_secret = #{little_secret.to_hash}"
    patate_data = data_bag_item('patate', 'user_data', data_bag_item('public_secret', new_resource.name)[:secret])
    Chef::Log.warn "patate_data = #{patate_data.to_hash}"
    secret_data_bag = data_bag_item(new_resource.name, 'secret', Chef::Config.knife[:userdata][:infra_secret])
    Chef::Log.warn "secret_data_bag = #{secret_data_bag.to_hash}"
    secret_own_data_bag = data_bag_item(new_resource.name, new_resource.name, Chef::Config.knife[:userdata][:infra_secret])
    Chef::Log.warn "secret_own_data_bag = #{secret_own_data_bag.to_hash}"
  end

  directory ::File.join(Chef::Config.knife[:userdata][:infra_home], '.chef') do
    user Chef::Config.knife[:userdata][:email_user]
  end

  Chef::Log.warn("Setting YP administrator #{new_resource.name} with parameter #{JSON.pretty_generate(Chef::Config.knife[:userdata])}")

  template ::File.join(Chef::Config.knife[:userdata][:infra_home], '.chef', 'infra_env.rb') do
    source 'infra_env.rb.erb'
    user Chef::Config.knife[:userdata][:email_user]
    variables userdata: Chef::Config.knife[:userdata]
  end
  template ::File.join(Chef::Config.knife[:userdata][:infra_home], '.chef', 'knife.rb') do
    source 'knife.rb.erb'
    user Chef::Config.knife[:userdata][:email_user]
    variables userdata: Chef::Config.knife[:userdata]
  end

  Chef::Log.warn('A little sleep to register logs')
  # sleep 60
end

action :install do
  own_user
end

action :build do
  own_user
end

action :clean do
  own_user(:delete)
end

action :release do
  own_user
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
  def own_user(action = :install)
    infra_user new_resource.name do
      secretname new_resource.secretname
      secretkey infra_secret
      action action
    end
  end
end
