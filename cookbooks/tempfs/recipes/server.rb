#
# Cookbook Name:: nfs
# Recipe::        server
#

#
#   Portions Copyright (c) 2012-2013 VMware, Inc. All Rights Reserved.
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

export_dirs = {}

# refer to http://linux.die.net/man/5/exports
nfs_option = "rw,nohide,no_root_squash,no_all_squash,async,insecure,no_acl,no_auth_nlm,no_subtree_check"

# clean up /etc/exports
execute "clean exports" do
  command %Q{cat /dev/null > /etc/exports}
end

directory node[:nfs][:pseudo_root_dir] do
  owner "mapred"
  group "hadoop"
  mode "0755"
  action :create
end

pseudo_count = 0

# Announce as a TempFS server, and announce each share as a capability
disks_mount_points.each do |mount_point|

  mount_dir = "#{mount_point}/tempfs"
  pseudo_dir = "#{node[:nfs][:pseudo_root_dir]}/export#{pseudo_count}"
  pseudo_count += 1

  # Create Dir
  [ mount_dir, pseudo_dir ].each do |dir|
    directory dir do
      owner "mapred"
      group "hadoop"
      mode  '0755'
      recursive true
      action    :create
    end
  end
  export_dirs[mount_dir] = pseudo_dir
end

# write configuration
execute "write pseudo root dir to exports config file" do
  command %Q{ echo "#{node[:nfs][:pseudo_root_dir]} *(#{nfs_option},fsid=0)" >> /etc/exports }
end

export_dirs.each do |mount_dir, pseudo_dir|
  execute "mount bind pseudo_dirs" do
    not_if "grep '#{pseudo_dir}' /etc/mtab > /dev/null"
    command %Q{ mount --bind #{mount_dir} #{pseudo_dir} }
  end
  execute "write each export dirs" do
    command %Q{ echo "#{pseudo_dir} *(#{nfs_option})" >> /etc/exports }
  end
end

service "start-#{node[:nfs][:nfs_service_name]}" do
  service_name node[:nfs][:nfs_service_name]
  action [ :disable, :start ]
  supports :status => true, :restart => true
end

service "start-rpcidmapd" do
  service_name "rpcidmapd"
  action [ :enable, :start ]
  supports :status => true, :restart => true
end

export_entries = export_dirs.values.map{ |dir| dir.split(/\//).last }

provide_service(node[:nfs][:nfs_service_name], :server => "nfs", :addr => node[:ipaddress], :export_entries => export_entries)
