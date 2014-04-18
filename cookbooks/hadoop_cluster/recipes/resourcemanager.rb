#
# Cookbook Name:: hadoop_cluster
# Recipe::        resourcemanager
#

#
# Copyright (c) 2012-2014 VMware, Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "hadoop_cluster"
install_namenode_if_has_namenode_role
install_datanode_if_has_datanode_role

# Install
hadoop_package node[:hadoop][:packages][:resourcemanager][:name]

# Regenerate Hadoop xml conf files with new Hadoop server address
include_recipe "hadoop_cluster::hadoop_conf_xml"

# Wait until HDFS is ready, because YARN depends on HDFS
include_recipe "hadoop_cluster::wait_for_hdfs"

service_name = node[:hadoop][:resourcemanager_service_name]

## Launch service
set_bootstrap_action(ACTION_START_SERVICE, service_name)

is_service_running = system("service #{service_name} status >/dev/null 2>&1")
service "restart-#{service_name}" do
  service_name service_name
  supports :status => true, :restart => true

  subscribes :restart, resources("template[/etc/hadoop/conf/core-site.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/hdfs-site.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/mapred-site.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/yarn-site.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/hadoop-env.sh]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/yarn-env.sh]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/hadoop-metrics2.properties]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/log4j.properties]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/capacity-scheduler.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/mapred-queue-acls.xml]"), :delayed
  notifies :create, resources("ruby_block[#{service_name}]"), :immediately
end if is_service_running

service "start-#{service_name}" do
  service_name service_name
  action [ :disable, :start ]
  supports :status => true, :restart => true

  notifies :create, resources("ruby_block[#{service_name}]"), :immediately
end

# Register with cluster_service_discovery
provide_service(service_name)

# Install HistoryServer
hadoop_package node[:hadoop][:packages][:historyserver][:name]

# Launch HistoryServer service
service "#{node[:hadoop][:historyserver_service_name]}" do
  action [ :disable, :start ]
  supports :status => true, :restart => true
end

clear_bootstrap_action
