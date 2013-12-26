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

include_recipe "hadoop_cluster"

# Install
hadoop_package node[:hadoop][:packages][:journalnode][:name]

# Add journalnode service script file because Hortonworks 2.0.x does not provide journalnode rpm.
if is_hdp2_distro
  template "/etc/default/hadoop-hdfs-journalnode" do
    source "hadoop-hdfs-journalnode-env.erb"
    mode "0644"
  end

  template "/etc/init.d/hadoop-hdfs-journalnode" do
    source "hadoop-hdfs-journalnode.erb"
    mode "0755"
  end
end

include_recipe "hadoop_cluster::hadoop_conf_xml"

# Create journalnode edits dir
edits_dir = "#{disks_mount_points[0]}/journalnode"
directory edits_dir do
  owner "hdfs"
  group "hdfs"
  mode "0755"
  recursive true
end

make_link("/var/lib/journalnode", edits_dir)

wait_for_zookeepers_service

# Launch service
set_bootstrap_action(ACTION_START_SERVICE, node[:hadoop][:journalnode_service_name])

is_journalnode_running = system("service #{node[:hadoop][:journalnode_service_name]} status >/dev/null 2>&1")
service "restart-#{node[:hadoop][:journalnode_service_name]}" do
  service_name node[:hadoop][:journalnode_service_name]
  supports :status => true, :restart => true

  subscribes :restart, resources("template[/etc/hadoop/conf/hadoop-env.sh]"), :delayed
  notifies :create, resources("ruby_block[#{node[:hadoop][:journalnode_service_name]}]"), :immediately
end if is_journalnode_running

service "start-#{node[:hadoop][:journalnode_service_name]}" do
  service_name node[:hadoop][:journalnode_service_name]
  action [ :disable, :start ]
  supports :status => true, :restart => true

  notifies :create, resources("ruby_block[#{node[:hadoop][:journalnode_service_name]}]"), :immediately
end

# Register with cluster_service_discovery
provide_service(node[:hadoop][:journalnode_service_name])

clear_bootstrap_action
