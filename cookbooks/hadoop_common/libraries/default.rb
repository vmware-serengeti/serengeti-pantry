#
#   Cookbook Name:: hadoop_common
#
#   Portions Copyright (c) 2012-2013 VMware, Inc. All Rights Reserved.
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

module HadoopCluster
  require 'resolv'
  require 'json'

  # Create a symlink to a directory, wiping away any existing dir that's in the way
  def force_link dest, src
    return if dest == src
    directory(dest) do
      action :delete
      recursive true
      not_if { File.symlink?(dest) }
      not_if { File.exists?(dest) and File.exists?(src) and File.realpath(dest) == File.realpath(src) }
    end
    link(dest) { to src }
  end

  def device_of_mgt_network server = nil
    return device_of_network(server, 'MGT_NETWORK')
  end

  def device_of_hdfs_network server = nil
    return device_of_network(server, 'HDFS_NETWORK')
  end

  def device_of_mapred_network server = nil
    return device_of_network(server, 'MAPRED_NETWORK')
  end

  def fqdn_of_mgt_network server = nil
    return fqdn_of_network(server, 'MGT_NETWORK')
  end

  def fqdn_of_hdfs_network server = nil
    return fqdn_of_network(server, 'HDFS_NETWORK')
  end

  def fqdn_of_mapred_network server = nil
    return fqdn_of_network(server, 'MAPRED_NETWORK')
  end

  def ip_of_mgt_network server = nil
    return ip_of_network(server, 'MGT_NETWORK')
  end

  def ip_of_hdfs_network server = nil
    return ip_of_network(server, 'HDFS_NETWORK')
  end

  def ip_of_mapred_network server = nil
    return ip_of_network(server, 'MAPRED_NETWORK')
  end

  def fqdn_of_network server, traffic_type
    server = node if server.nil?
    fqdn = nil
    if !server[:ip_configs][traffic_type].nil? and !server[:ip_configs][traffic_type].empty?
      fqdn = server[:ip_configs][traffic_type][0]['fqdn']
      if fqdn.to_s.empty?
        # if remote server's fqdn is not yet updated, try to fetch 
        # by querying dns directly
        fqdn = fqdn_of_ip(ip_of_network(server, traffic_type))
      end
    else
      # if node[:ip_configs] does not contain given "traffic_type"
      fqdn = fqdn_of_network(server, 'MGT_NETWORK')
    end
    return fqdn
  end

  def device_of_network server, traffic_type
    server = node if server.nil?
    device = server[:ip_configs]['MGT_NETWORK'][0]['device']
    if !server[:ip_configs][traffic_type].nil? and !server[:ip_configs][traffic_type].empty?
      # currently this function is only called from localhost, no need to check NPE
      # since this attribute is set in pre_run
      device = server[:ip_configs][traffic_type][0]['device']
    end
    return device
  end

  def ip_of_network server, traffic_type
    server = node if server.nil?
    ip = server[:ip_configs]['MGT_NETWORK'][0]['ip_address'] # by default return ip of MGT_NETWORK
    if !server[:ip_configs][traffic_type].nil? and !server[:ip_configs][traffic_type].empty?
      ip = server[:ip_configs][traffic_type][0]['ip_address']
    end
    return ip
  end

  def update_ipconfigs
    file_name = "/etc/portgroup2eth.json"
    return unless File.exist?(file_name)
    port2dev = JSON.parse(File.new(file_name, "r").gets)
    ip_configs = JSON.parse(node[:ip_configs].to_json)
    ip_configs.each do |net_type, net_list|
      index = 0
      net_list.each do |net|
        device = port2dev[net['port_group_name']]
        ip_configs[net_type][index]['device'] = device
        node[:network][:interfaces][device][:addresses].keys.each do |ip|
          if ip =~ /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
            Chef::Log.debug("got portgroup: #{net['port_group_name']}, device: #{device}, ip: #{ip}")
            ip_configs[net_type][index]['ip_address'] = ip
            ip_configs[net_type][index]['fqdn'] = fqdn_of_ip(ip)
            break
          end
        end
        index += 1
      end
    end
    node.set[:ip_configs] = ip_configs
    node.save
  end

  def set_hostname hostname
    system <<EOF
        hostname #{hostname}
        CONF=/etc/sysconfig/network
        if `grep -q HOSTNAME $CONF` ; then
          sed -i s/^HOSTNAME=.*/HOSTNAME=#{hostname}/ $CONF
        else
          echo "HOSTNAME=#{hostname}" >> $CONF
        fi
EOF
    Chef::Log.info("hostname is set to #{hostname}")
  end

  # fetch fqdn from dns server, if fail, return ip address instead
  def fqdn_of_ip ip
    Chef::Log.debug("Trying to resolve IP #{ip} to FQDN")
    fqdn = ip
    begin
      # set DNS resolution timeout to 6 seconds, otherwise it will take about 80s then throws exception when DNS server is not reachable
      fqdn = Timeout.timeout(6) { Resolv.getname(ip) }
      Chef::Log.info("Resolved IP #{ip} to FQDN #{fqdn}")
    rescue StandardError => e
      Chef::Log.warn("Unable to resolve IP #{ip} to FQDN due to #{e}")
    end
    return fqdn
  end

  def make_link src, target
    return if src == target
    link(src) do
      to target
      not_if { File.exists?(src) }
    end
  end

  # Use `file -s` to identify volume type: ohai doesn't seem to want to do so.
  def fstype_from_file_magic(dev)
    return 'ext4' unless File.exists?(dev)
    dev = File.realpath(dev)
    dev_type_str = `file -s '#{dev}'`
    case
    when dev_type_str =~ /SGI XFS/           then 'xfs'
    when dev_type_str =~ /Linux.*ext2/       then 'ext2'
    when dev_type_str =~ /Linux.*ext3/       then 'ext3'
    else                                          'ext4'
    end
  end

  # FQDN of the server (i.e the chef node) which has the specified role
  def fqdn_of_server server, role = nil
    fqdn = fqdn_of_mgt_network(server)
    if [
      'hadoop_namenode',
      'hadoop_secondarynamenode',
      'hadoop_journalnode',
      'hadoop_datanode',
      'hbase_master',
      'hbase_regionserver'
    ].compact.include?(role)
      fqdn = fqdn_of_hdfs_network(server)
    elsif [
      'hadoop_tasktracer',
      'hadoop_resourcemanager',
      'hadoop_jobtracker',
      'hadoop_nodemanager'
    ].compact.include?(role)
      fqdn = fqdn_of_mapred_network(server)
    elsif [
      'zookeeper'
    ].compact.include?(role)
      fqdn = ip_of_hdfs_network(server)
    end
    return fqdn
  end

  # return an Array of mount points of the mounted data disks
  def disks_mount_points
    node[:disk][:data_disks].keys
  end

  # run the given code block in a Chef Ruby Block
  # see http://wiki.opscode.com/display/chef/Resources#Resources-RubyBlock
  def run_in_ruby_block(name, in_chef_ruby_block = true, &code)
    return unless name and code

    if !in_chef_ruby_block
      return code.call
    end

    ruby_block name.to_s do
      block do
        code.call
      end
    end
  end

  # check Internet connection
  def is_connected_to_internet
    Chef::Log.info('checking whether this machine is connected to the Internet')

    # wget will create an empty file even if it can't download the remote file
    # when not connected to Internet, in each try of wget, it will try to connect to several IPs (resolved by the dns name) 
    # and every failed connect will take {--timeout} seconds to timeout.
    tmpfile = '/tmp/internet-connected'
    execute 'try to access google homepage' do
      command %Q{
        rm -f #{tmpfile}
        wget --tries=1 --timeout=3 http://www.google.com/ -O /tmp/google-homepage >/dev/null 2>&1 && touch #{tmpfile}
        rm -f /tmp/google-homepage
      }
      timeout 30
      ignore_failure true
      action :nothing
    end.run_action(:run)

    connected = File.exist?(tmpfile)
    if connected
      Chef::Log.info('this machine is connected to the Internet')
    else
      Chef::Log.info('this machine is not connected to the Internet')
    end

    connected
  end

  # some software uses '#export JAVA_HOME' (e.g. MapR 3.1).
  # some software only requires 'export JAVA_HOME' at the end of the file.
  def set_java_home(file)
    execute "Set JAVA_HOME in #{file}" do
      only_if { File.exists?(file) }
      not_if "grep '^export JAVA_HOME' #{file}"
      command %Q{
sed -i 's|^#export JAVA_HOME.*|. /etc/profile; . /etc/environment; \\nexport JAVA_HOME|' #{file}

cat <<EOF >> #{file}

# detect JAVA_HOME
. /etc/profile
. /etc/environment
export JAVA_HOME

EOF
      }
    end
  end

  def wait_for_disks_ready
    set_action(ACTION_FORMAT_DISK, 'format_disk')
    while true
      if `/usr/sbin/vmware-rpctool 'info-get guestinfo.disk.format.status'`.strip == "Disks Ready"
        break
      else
        sleep 1
      end
    end
  end

  # Generate ssh rsa keypair for the specified user
  def generate_ssh_rsa_keypair(username, homedir = nil)
    homedir ||= "/home/#{username}"
    directory "#{homedir}/.ssh" do
      owner username
      group username
      mode  '0700'
      action :nothing
    end.run_action(:create)

    rsa_file = "#{homedir}/.ssh/id_rsa"
    execute "generate ssh keypair for user #{username}" do
      not_if { File.exist?(rsa_file) }
      user username
      command "ssh-keygen -t rsa -N '' -f #{rsa_file}"
      action :nothing
    end.run_action(:run)

    ssh_config_file = "#{homedir}/.ssh/config"
    if !File.exist?(ssh_config_file)
      file ssh_config_file do
        owner username
        group username
        mode  '0640'
        content 'StrictHostKeyChecking no'
        action :nothing
      end.run_action(:create)
    end

    # save public key of username to Chef Node
    keyname = "rsa_pub_key_of_#{username}"
    rsa_pub_key = File.read("#{homedir}/.ssh/id_rsa.pub")
    if node[keyname] != rsa_pub_key
      node.normal[keyname] = rsa_pub_key
      node.save
    end
  end

  # Return rsa public keys of the specified user on the nodes with the specified role
  def rsa_pub_keys_of_user(username, role)
    rsa_pub_keys_of_user_for_condition(username, {"role" => role})
  end

  # Return rsa public keys of the specified user on the nodes with the conditions
  def rsa_pub_keys_of_user_for_condition(username, conditions)
    nodes_num = all_nodes_count(conditions)
    return [] if nodes_num == 0
    key = "rsa_pub_key_of_#{username}"
    conditions.merge!(key => "*")
    nodes = providers_for(key, conditions, true, nodes_num)
    nodes.map { |node| node[key] }
  end

  # Setup keyless ssh for the user from the node which has the role to this node
  def setup_keyless_ssh_for_user_on_role(username, role)
    keys = rsa_pub_keys_of_user(username, role)
    file "/home/#{username}/.ssh/authorized_keys" do
      owner username
      group username
      mode  '0640'
      content keys.join("\n")
      action :nothing
    end.run_action(:create)
  end

  def grant_sudo_to_user(username)
    sudo_setting = "#{username}     ALL=(ALL) NOPASSWD: ALL"
    execute "grant sudo priviledge to user #{username}" do
      not_if "grep '#{sudo_setting}' /etc/sudoers"
      command %Q{
        echo "#{sudo_setting}" >> /etc/sudoers
      }
    end
  end

  def is_rhel5
    ["redhat", "centos", "oracle"].include?(node['platform']) and (node['platform_version'] =~ /5/) == 0
  end

  def package_installed?(name)
    name = name.to_s.split[0]
    if name.empty?
      return false
    else
      File.exist?("/usr/lib/#{name}") or system("rpm -q #{name}")
    end
  end
end
