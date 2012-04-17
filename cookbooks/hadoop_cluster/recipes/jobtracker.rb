#
# Cookbook Name:: hadoop
# Recipe:: jobtracker
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
hadoop_package node[:hadoop][:packages][:jobtracker][:name]

if is_hadoop_yarn? then
# Fix CDH4b1 bug: 'service stop hadoop-yarn-*' should wait for SLEEP_TIME before return
%w[hadoop-yarn-resourcemanager].each do |service_file|
  template "/etc/init.d/#{service_file}" do
    owner "root"
    group "root"
    mode  "0755"
    source "#{service_file}.erb"
  end
end
end

# Register with cluster_service_discovery
provide_service ("#{node[:cluster_name]}-#{node[:hadoop][:jobtracker_service_name]}")
# Regenerate Hadoop xml conf files with new Hadoop server address
node.run_state[:seen_recipes].delete("hadoop_cluster::hadoop_conf_xml") # check http://tickets.opscode.com/browse/CHEF-1406
include_recipe "hadoop_cluster::hadoop_conf_xml"

# Launch service
service "#{node[:hadoop][:jobtracker_service_name]}" do
  action [ :enable, :restart ]
  running true
  supports :status => true, :restart => true
end


if is_hadoop_yarn? then

# Install
hadoop_package "mapreduce-historyserver"

# Fix CDH4b1 bug: 'service stop hadoop-yarn-*' should wait for SLEEP_TIME before return
%w[hadoop-mapreduce-historyserver].each do |service_file|
  template "/etc/init.d/#{service_file}" do
    owner "root"
    group "root"
    mode  "0755"
    source "#{service_file}.erb"
  end
end

# Launch HistoryServer service
service "#{node[:hadoop][:historyserver_service_name]}" do
  action [ :enable, :restart ]
  running true
  supports :status => true, :restart => true
end

end # is_hadoop_yarn?
