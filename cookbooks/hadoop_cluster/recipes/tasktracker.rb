#
# Cookbook Name:: hadoop_cluster
# Recipe::        tasktracker
#
# Copyright 2009, Opscode, Inc.
# Portions copyright © 2012 VMware, Inc. All rights Reserved.
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
hadoop_package node[:hadoop][:packages][:tasktracker][:name]

# Launch Service
set_bootstrap_action(ACTION_START_SERVICE, node[:hadoop][:tasktracker_service_name])
service "#{node[:hadoop][:tasktracker_service_name]}" do
  action [ :enable, :restart ]
  running true
  supports :status => true, :restart => true
end
