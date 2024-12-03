# To learn more about Custom Resources, see https://docs.chef.io/custom_resources/

provides :infra_user

default_action :cycle

property :secretname, String, default: ''
property :secretkey, String, default: ''

property :live_stream, [TrueClass, FalseClass], default: false

unified_mode true

action :begin do
  own_data(:build)
  set_chef_user
end

action :download do
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
  infra_chefuser
end

action :check do
end

action :install do
  infra_chefuser
end

action :strip do
end

action :end do
  infra_chefuser(:delete)
end

action :recycle do
  action_delete
  action_cycle
end

action :cycle do
  # action_clean
  # action_prepare
  # action_build
  # action_install
  # action_test
  # action_release
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
  def generate_dir(path, path_data = { "#{ENV['USER']}": { home: Dir.home(ENV['USER']), group: ENV['GROUP'], mode: 0755} })
    username = path_data.keys[0]
    group = path_data.key?(:group) ? path_data['group'] : username
    directory path do
      recursive true
      group path_data.key?(:group) ? path_data['group'] : username
      owner username
      mode '0750'
    end
  end

  def set_chef_user
    path_data = { "#{name}": userdata.merge({ mode: 0750 }) }
    generate_dir(home, path_data)
    generate_dir(::File.join(home, '.aws'), path_data)
    generate_dir(::File.join(home, '.gnupg'), path_data)
    generate_dir(::File.join(home, '.config'), path_data)
    generate_dir(::File.join(home, '.vagrant.d'), path_data)
    generate_dir(::File.join(home, '.atom'), path_data)
    generate_dir(::File.join(home, '.chef'), path_data)
    generate_dir(::File.join(home, '.gem'), path_data)
    generate_dir(::File.join(home, '.local', 'share', 'gem'), path_data)
    generate_dir(sshdir, path_data.merge({ "#{name}": { mode: 0700 }}))

    cookbook_file "sshhomedir/teamcity" do
      source 'teamcity'
      path ::File.join(sshdir, 'teamcity')
      mode '0600'
      owner username
      group group
    end

    ruby_block 'ruby for chefdk' do
      user username
      cwd home
      block do
        ::File.open('.bashrc', 'a') do |bashrc|
          bashrc.write 'eval "$(chef shell-init bash)"'
          bashrc.write userdata[:additionnal_path]
        end
      end
    end

    cookbook_file identity_key do
      source ::File.join("certs", new_resource.name, "new_#{new_resource.name}.pem")
      mode '0400'
    end

    template user_client_file do
      source "knife.rb.erb"
      variables generate_config
    end

    cookbook_file ::File.join(sshdir, 'id_rsa') do
      source 'certs/ssh/id_rsa_chef_git'
      mode '0400'
    end

    cookbook_file ::File.join(sshdir, 'id_rsa.pub') do
      source 'certs/ssh/id_rsa_chef_git.pub'
      mode '0400'
    end

    template ::File.join(sshdir, 'config') do
      source 'ssh_config.erb'
      variables(
        identityfile: ::File.join(::File.join(home, '.ssh'), 'id_rsa')
      )
      mode '0400'
    end

    file known_hosts_file do
      mode '0400'
    end

    execute 'ssh git@git.ypg.com -p 7999 -o StrictHostKeyChecking=no "echo"' do
      live_stream new_resource.live_stream
      returns [0, 1]
    end
  end

  def infra_chefuser(action = :create)
    Chef::Log.warn("Creating local user #{new_resource.name} with secretkey '#{new_resource.secretkey}'")
    Chef::Log.warn("Local user data is #{data_bag_item(new_resource.name, 'user_data').to_hash}")
    user new_resource.name do
      username new_resource.name
      gid group
      password UnixCrypt::SHA512.build(data_bag_item(new_resource.name, 'user_data', new_resource.secretkey)[:email_password])
      home home
      shell shell
      system system
      manage_home manage_home
      action action
    end
  end

  def own_data(action = :install)
    infra_userdata new_resource.name do
      owner new_resource.name
      userdata userdata
      secret new_resource.secretkey
      secretname new_resource.secretname
      action action
    end
  end
end
