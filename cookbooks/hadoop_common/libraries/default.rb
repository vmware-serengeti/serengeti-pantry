#
#   Cookbook Name:: hadoop_common
#
#   Portions Copyright (c) 2012 VMware, Inc. All Rights Reserved.
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

    tmpfile = '/tmp/google-homepage'

    file tmpfile do
      action :nothing
    end.run_action(:delete)

    remote_file tmpfile do
      source 'http://www.google.com/'
      ignore_failure true
      action :nothing
    end.run_action(:create)

    connected = File.exist?(tmpfile)
    if connected
      Chef::Log.info('this machine is connected to the Internet')
    else
      Chef::Log.info('this machine is not connected to the Internet')
    end

    connected
  end
end