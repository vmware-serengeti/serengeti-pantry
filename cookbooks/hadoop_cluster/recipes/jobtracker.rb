#
# Cookbook Name:: hadoop_cluster
# Recipe::        jobtracker
#

#
# Copyright 2009, Opscode, Inc.
# Portions Copyright (c) 2012-2013 VMware, Inc. All Rights Reserved.
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

is_jobtracker_running = system("service #{node[:hadoop][:jobtracker_service_name]} status 1>2 2>/dev/null")
service "restart-#{node[:hadoop][:jobtracker_service_name]}" do
  service_name node[:hadoop][:jobtracker_service_name]
  supports :status => true, :restart => true

  subscribes :restart, resources("template[/etc/hadoop/conf/core-site.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/hdfs-site.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/mapred-site.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/hadoop-env.sh]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/log4j.properties]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/hadoop-metrics.properties]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/capacity-scheduler.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/mapred-queue-acls.xml]"), :delayed
  notifies :create, resources("ruby_block[#{node[:hadoop][:jobtracker_service_name]}]"), :immediately
  if is_hortonworks_hmonitor_jobtracker_enabled
    notifies :start, resources("service[#{node[:hadoop][:hmonitor_ha_service]}]"), :delayed
  end
end if is_jobtracker_running

service "start-#{node[:hadoop][:jobtracker_service_name]}" do
  service_name node[:hadoop][:jobtracker_service_name]
  action [ :disable, :start ]
  supports :status => true, :restart => true

  notifies :create, resources("ruby_block[#{node[:hadoop][:jobtracker_service_name]}]"), :immediately
  if is_hortonworks_hmonitor_jobtracker_enabled
    notifies :start, resources("service[#{node[:hadoop][:hmonitor_ha_service]}]"), :delayed
  end
end

# Register with cluster_service_discovery
provide_service(node[:hadoop][:jobtracker_service_name])

clear_bootstrap_action
