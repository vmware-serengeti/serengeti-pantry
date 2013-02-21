#
# Cookbook Name:: nfs
# Recipe::        default
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

include_recipe "java::sun"
include_recipe "hadoop_common::mount_disks"
include_recipe "hadoop_common::add_repo"

group 'hadoop' do
  group_name 'hadoop'
  gid         300
  action      [:create, :manage]
end

user 'mapred' do
  comment    'Hadoop Mapred Runner'
  uid        303
  group      'hadoop'
  shell      "/bin/bash"
  password   nil
  action     [:create, :manage]
end

unless File.exist?("/etc/init.d/nfs")
  set_bootstrap_action(ACTION_INSTALL_PACKAGE, node[:nfs][:package_name])
  package node[:nfs][:package_name] do
    action :install
    notifies :create, resources("ruby_block[#{node[:nfs][:package_name]}]"), :immediately
  end
end

# nfs service depends on portmap service
service "start-portmap" do
  service_name "portmap"
  action [ :enable, :start ]
  supports :status => true, :restart => true
end

bash "configure service rpcidmapd" do
  code <<EOF
  sed -i 's/^Nobody-User.*/Nobody-User = mapred/' /etc/idmapd.conf
  sed -i 's/^Nobody-Group.*/Nobody-Group = hadoop/' /etc/idmapd.conf
EOF
end
