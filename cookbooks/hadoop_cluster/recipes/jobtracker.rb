#
# Cookbook Name:: hadoop_cluster
# Recipe::        jobtracker
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
install_namenode_if_has_namenode_role
install_datanode_if_has_datanode_role

# Install
hadoop_package node[:hadoop][:packages][:jobtracker][:name]

# Regenerate Hadoop xml conf files with new Hadoop server address
include_recipe "hadoop_cluster::hadoop_conf_xml"

# when starting Jobtracker daemon, it requires at least 1 datanode to replicate jobtracker.info,
# so wait until HDFS is ready.
include_recipe "hadoop_cluster::wait_for_hdfs"

## Launch service
set_bootstrap_action(ACTION_START_SERVICE, node[:hadoop][:jobtracker_service_name])

if is_hortonworks_hmonitor_jobtracker_enabled
  # Install Hortonworks HMonitor vSphere HA (see http://hortonworks.com/thankyou-hdp12-hakit-vmw/?mdl=13577&ao=0&lnk=0)
  hadoop_ha_package node[:hadoop][:hmonitor_ha_package]
  # Before start/restart jobtracker service, we need to stop hmonitor service if it's running,
  # otherwise, hmonitor service will detect jobtracker is down then reset the VM.
  stop_ha_service node[:hadoop][:hmonitor_ha_service]
end

is_jobtracker_running = system("service #{node[:hadoop][:jobtracker_service_name]} status >/dev/null 2>&1")
service "restart-#{node[:hadoop][:jobtracker_service_name]}" do
  service_name node[:hadoop][:jobtracker_service_name]
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
  notifies :create, resources("ruby_block[#{node[:hadoop][:jobtracker_service_name]}]"), :immediately
end if is_jobtracker_running

service "start-#{node[:hadoop][:jobtracker_service_name]}" do
  service_name node[:hadoop][:jobtracker_service_name]
  action [ :disable, :start ]
  supports :status => true, :restart => true

  notifies :create, resources("ruby_block[#{node[:hadoop][:jobtracker_service_name]}]"), :immediately
end

# Start hmonitor ha service at the end of bootstrapping
if is_hortonworks_hmonitor_jobtracker_enabled
  start_ha_service node[:hadoop][:hmonitor_ha_service], true
end

# Register with cluster_service_discovery
provide_service(node[:hadoop][:jobtracker_service_name])

clear_bootstrap_action
