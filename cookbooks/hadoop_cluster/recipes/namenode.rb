#
# Cookbook Name:: hadoop
# Recipe:: namenode
#
# Copyright 2009, Opscode, Inc.
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
hadoop_package "hdfs-namenode"

# Register with cluster_service_discovery
provide_service ("#{node[:cluster_name]}-hdfs-namenode")
# Regenerate Hadoop xml conf files with new Hadoop server address
node.run_state[:seen_recipes].delete("hadoop_cluster::hadoop_conf_xml") # this is a work around; check http://tickets.opscode.com/browse/CHEF-1406
include_recipe "hadoop_cluster::hadoop_conf_xml"

# Format namenode
include_recipe "hadoop_cluster::bootstrap_format_namenode"

# Launch NameNode service
service "#{node[:hadoop][:namenode_service_name]}" do
  action [ :enable, :restart ]
  running true
  supports :status => true, :restart => true
end

# 'service hadoop-0.20-namenode start' launchs the hadoop process then return without ensuring all listening ports are up.
Chef::Log.info('Wait until namenode service starts listening at network ports')
sleep 5

# Set hdfs permission on only after formatting namenode
include_recipe "hadoop_cluster::bootstrap_hdfs_dirs"
