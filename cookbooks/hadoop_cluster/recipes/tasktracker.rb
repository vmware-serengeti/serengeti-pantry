#
# Cookbook Name:: hadoop_cluster
# Recipe::        tasktracker
#

#
# Copyright 2009, Opscode, Inc.
# Portions Copyright (c) 2012-2014 VMware, Inc. All Rights Reserved.
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
install_datanode_if_has_datanode_role
install_jobtracker_if_has_jobtracker_role

# Install
hadoop_package node[:hadoop][:packages][:tasktracker][:name]

wait_for_jobtracker_service

## Launch Service
set_bootstrap_action(ACTION_START_SERVICE, node[:hadoop][:tasktracker_service_name])

is_tasktracker_running = system("service #{node[:hadoop][:tasktracker_service_name]} status >/dev/null 2>&1")

service "restart-#{node[:hadoop][:tasktracker_service_name]}" do
  service_name node[:hadoop][:tasktracker_service_name]
  supports :status => true, :restart => true

  subscribes :restart, resources("template[/etc/hadoop/conf/core-site.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/hdfs-site.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/mapred-site.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/hadoop-env.sh]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/hadoop-metrics.properties]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/hadoop-metrics2.properties]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/log4j.properties]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/capacity-scheduler.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/mapred-queue-acls.xml]"), :delayed
  notifies :create, resources("ruby_block[#{node[:hadoop][:tasktracker_service_name]}]"), :immediately
end if is_tasktracker_running

service "start-#{node[:hadoop][:tasktracker_service_name]}" do
  service_name node[:hadoop][:tasktracker_service_name]
  action [ :disable, :start ]
  supports :status => true, :restart => true

  notifies :create, resources("ruby_block[#{node[:hadoop][:tasktracker_service_name]}]"), :immediately
end

# Register with cluster_service_discovery
provide_service(node[:hadoop][:tasktracker_service_name])

clear_bootstrap_action
