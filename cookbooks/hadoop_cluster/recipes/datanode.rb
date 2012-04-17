#
# Cookbook Name:: hadoop
# Recipe::        datanode
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
hadoop_package node[:hadoop][:packages][:datanode][:name]

=begin 
# should run this only after namenode is formatted
# Remove current cluster id
directory "/mnt/hadoop/hdfs/data/current" do
  ignore_failure true
  recursive true
  action :delete
end
=end

# Launch
service "#{node[:hadoop][:datanode_service_name]}" do
  action [ :enable, :restart ]
  running true
  supports :status => true, :restart => true
end
