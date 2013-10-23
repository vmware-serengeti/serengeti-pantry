#
# Cookbook Name:: hadoop_cluster
# Recipe::        wait_for_hdfs
#
# Copyright (c) 2012-2013 VMware, Inc. All Rights Reserved.
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

run_in_ruby_block "wait_for_hdfs" do
  Chef::Log.info('Wait until the datanodes daemon are started.')
  all_providers_for_service(node[:hadoop][:datanode_service_name])
  Chef::Log.info('The datanodes daemon are started. Wait until namenode adds the datanodes and is able to place replica.')
end

include_recipe "hadoop_cluster::wait_on_hdfs_safemode"

run_in_ruby_block "hdfs_is_ready" do
  Chef::Log.info('HDFS is ready to place replica now.')
end
