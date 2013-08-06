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
    dev_type_str = `file -s '#{dev}'`
    case
    when dev_type_str =~ /SGI XFS/           then 'xfs'
    when dev_type_str =~ /Linux.*ext2/       then 'ext2'
    when dev_type_str =~ /Linux.*ext3/       then 'ext3'
    else                                          'ext4'
    end
  end

  # return an Array of mount points of the mounted data disks
  def disks_mount_points
    node[:disk][:data_disks].keys
  end

  # run the given code block in a Chef Ruby Block
  # see http://wiki.opscode.com/display/chef/Resources#Resources-RubyBlock
  def run_in_ruby_block(name, &code)
    return unless name and code
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
        wget --tries=1 --timeout=3 http://www.google.com/ -O /tmp/google-homepage 1>2 2>/dev/null && touch #{tmpfile}
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

  def set_java_home(file)
    execute "Set JAVA_HOME in #{file}" do
      only_if { File.exists?(file) }
      not_if "grep '^export JAVA_HOME' #{file}"
      command %Q{
cat <<EOF >> #{file}
# detect JAVA_HOME
. /etc/profile
. /etc/environment
export JAVA_HOME
EOF
      }
    end
  end

  # format and mount local data disks
  def mount_disks(dev2disk, mp2dev)
    ## Format all attached disk devices in parallel
    # use '&' to run as background shell job and 'wait' to wait for all jobs.
    # if the background jobs fail (e.g format disk fails), 'wait' will always return 0,
    # but the resource 'mount' afterward will throw error.
    log = '/tmp/serengeti-format-disks.log'
    filename = '/tmp/serengeti-format-disks.sh'
    format_disks = ''
    dev2disk.each do |dev, disk|
      next if !File.exist?(disk) or File.exist?(dev) # disk not exists or already formatted
      format_disks << "format_disk #{disk} #{dev} & \n"
    end

    if !format_disks.empty?
      set_action(ACTION_FORMAT_DISK, 'format_disk')
      file filename do
        mode "0755"
        content %Q{
function format_disk_internal()
{
  kernel=`uname -r | cut -d'-' -f1`
  first=`echo $kernel | cut -d '.' -f1`
  second=`echo $kernel | cut -d '.' -f2`
  third=`echo $kernel | cut -d '.' -f3`
  num=$[ $first*10000 + $second*100 + $third ]

  # we cannot use [[ "$kernel" < "2.6.28" ]] here because linux kernel 
  # has versions like "2.6.5"
  if [ $num -lt 20628 ];
  then
    mkfs -t ext3 -b 4096 $1;
  else
    mkfs -t ext4 -b 4096 $1;
  fi;
}

function format_disk()
{
  flag=1
  while [ $flag -ne 0 ] ; do
    echo "Running sfdisk -uM $1. Occasionally it will fail, we will re-run."
    echo ",,L" | sfdisk -uM $1
    flag=$?
    sleep 3
  done

  echo "y" | format_disk_internal $2
}

echo Started on `date`
#{format_disks}
wait
echo Finished on `date`
        }
        action :nothing
      end.run_action(:create)

      execute "formatting data disks" do
        command "#{filename} > #{log}"
        action :nothing
      end.run_action(:run)
      clear_action
    end

    ## Mount data disk, make hadoop dirs on them
    mp2dev.each do |mount_point, dev|
      next unless File.exists?(node[:disk][:disk_devices][dev])

      Chef::Log.info "mounting data disk #{dev} at #{mount_point}" unless File.exists?(mount_point)
      directory mount_point do
        only_if{ File.exists?(dev) }
        owner     'root'
        group     'root'
        mode      '0755'
        action    :create
      end

      dev_fstype = fstype_from_file_magic(dev)
      mount mount_point do
        only_if{ dev && dev_fstype }
        device dev
        options 'noatime'
        fstype dev_fstype
      end

      # Chef Resource mount doesn't enable automatically mount disks when OS starts up. We add it here.
      mount_device_command = "#{dev}\t\t#{mount_point}\t\t#{dev_fstype}\tdefaults\t0 0"
      execute 'add mount info into /etc/fstab if not added' do
        only_if "grep '#{dev}' /etc/mtab  > /dev/null"
        not_if  "grep '#{dev}' /etc/fstab > /dev/null"
        command %Q{
        echo "#{mount_device_command}" >> /etc/fstab
        }
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
      node[keyname] = rsa_pub_key
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
end
