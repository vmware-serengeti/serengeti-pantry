#
# Cookbook Name:: hadoop_cluster
# Recipe::        jobtracker
#

#
# Copyright 2009, Opscode, Inc.
# Portions Copyright (c) 2012 VMware, Inc. All Rights Reserved.
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

# Install
hadoop_package node[:hadoop][:packages][:jobtracker][:name]
hadoop_ha_package node[:hadoop][:packages][:jobtracker][:name] unless node.role? "hadoop_namenode"

# Register with cluster_service_discovery
provide_service ("#{node[:cluster_name]}-#{node[:hadoop][:jobtracker_service_name]}")
# Regenerate Hadoop xml conf files with new Hadoop server address
node.run_state[:seen_recipes].delete("hadoop_cluster::hadoop_conf_xml") # check http://tickets.opscode.com/browse/CHEF-1406
include_recipe "hadoop_cluster::hadoop_conf_xml"

# Launch service
set_bootstrap_action(ACTION_START_SERVICE, node[:hadoop][:jobtracker_service_name])
service "#{node[:hadoop][:jobtracker_service_name]}" do
  action [ :enable, :start ]
  supports :status => true, :restart => true

  subscribes :restart, resources("template[/etc/hadoop/conf/core-site.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/hdfs-site.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/mapred-site.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/hadoop-env.sh]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/log4j.properties]"), :delayed
  notifies :create, resources("ruby_block[#{node[:hadoop][:jobtracker_service_name]}]"), :immediately
  if ((node[:hadoop][:ha_enabled]) && (node.role? "hadoop_namenode")) then
    notifies :restart, resources("service[hmonitor-namenode-monitor]"), :delayed
  end
end

# Launch service level ha monitor
enable_ha_service node[:hadoop][:packages][:jobtracker][:name], "hmonitor-jobtracker-monitor" unless node.role? "hadoop_namenode"
