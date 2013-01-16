#
# Cookbook Name:: nfs
# Recipe::        server
#

#
#   Portions Copyright (c) 2012 VMware, Inc. All Rights Reserved.
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

include_recipe "tempfs::default"

export_dirs = []

# refer to http://linux.die.net/man/5/exports
nfs_option = "*(rw,async,no_root_squash,no_all_squash)"

# clean up /etc/exports
execute "create exports" do
  command %Q{cat /dev/null > /etc/exports}
end

# Announce as a TempFS server, and announce each share as a capability
disks_mount_points.each do |mount_point|
  # Remove dir
  directory "#{mount_point}/tempfs" do
    action :delete
    recursive true
  end

  mount_dir = "#{mount_point}/tempfs"

  # Create Dir
  directory mount_dir do
    owner "mapred"
    group "hadoop"
    mode  '0755'
    recursive true
    action    :create
  end
  export_dirs << mount_dir
end

# write configuration
export_dirs.each do |dir|
  execute "write exports" do
    command %Q{ echo "#{dir} #{nfs_option}" >> /etc/exports }
  end
end

service "start-#{node[:nfs][:nfs_service_name]}" do
  service_name node[:nfs][:nfs_service_name]
  action [ :enable, :start ]
  supports :status => true, :restart => true
end

provide_service(node[:nfs][:nfs_service_name], :server => "nfs", :addr => node[:ipaddress], :export_dirs => export_dirs)
