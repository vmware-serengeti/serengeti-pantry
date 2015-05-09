#
# Cookbook Name:: hadoop_cluster
# Recipe::        namenode
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

# Install
hadoop_package node[:hadoop][:packages][:namenode][:name]

# Regenerate Hadoop xml conf files with new Hadoop server address
include_recipe "hadoop_cluster::hadoop_conf_xml"

# for Bigtop Hadoop YARN packages (e.g. CDH4, Pivotal HD 1.0)
hadoop_dir = hadoop_home_dir
hdfs_dir = hadoop_hdfs_dir
force_link("#{hdfs_dir}/libexec", "#{hadoop_dir}/libexec") if hdfs_dir

if node[:hadoop][:namenode_ha_enabled]
  # Formatting namenode in a Namenode HA cluster depends on JournalNodes service
  wait_for_journalnodes_service
end

# Format namenode
if is_primary_namenode
  include_recipe "hadoop_cluster::bootstrap_format_namenode"
else
  include_recipe "hadoop_cluster::bootstrap_format_standbynamenode"
end

## Launch NameNode service
set_bootstrap_action(ACTION_START_SERVICE, node[:hadoop][:namenode_service_name])

if is_hortonworks_hmonitor_namenode_enabled
  # Install Hortonworks HMonitor vSphere HA (see http://hortonworks.com/thankyou-hdp12-hakit-vmw/?mdl=13577&ao=0&lnk=0)
  hadoop_ha_package node[:hadoop][:hmonitor_ha_package]
  # Before start/restart namenode service, we need to stop hmonitor service if it's running,
  # otherwise, hmonitor service will detect namenode is down then reset the VM.
  stop_ha_service node[:hadoop][:hmonitor_ha_service]
end

is_namenode_running = system("service #{node[:hadoop][:namenode_service_name]} status >/dev/null 2>&1")
service "restart-#{node[:hadoop][:namenode_service_name]}" do
  service_name node[:hadoop][:namenode_service_name]
  supports :status => true, :restart => true

  subscribes :restart, resources("template[/etc/hadoop/conf/core-site.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/hdfs-site.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/hadoop-env.sh]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/hadoop-metrics.properties]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/hadoop-metrics2.properties]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/log4j.properties]"), :delayed
  unless ['create', 'launch'].include?(node[:cluster_action])
    # When new nodes are added into this cluster, Ironfan knife command is 'cluster create' or 'cluster launch'.
    # chef-client will only append new lines to /etc/hadoop/conf/topology.data (containing ip to rack mapping), and no existing lines are updated.
    # And when Namenode adds a new Datanode (having a new IP), it will lookup topology.data to find its rack info.
    # So there is no need to restart Namenode daemon in this case.
    subscribes :restart, resources("template[/etc/hadoop/conf/topology.data]"), :delayed
  end
  notifies :create, resources("ruby_block[#{node[:hadoop][:namenode_service_name]}]"), :immediately
end if is_namenode_running

service "start-#{node[:hadoop][:namenode_service_name]}" do
  service_name node[:hadoop][:namenode_service_name]

  # Do not start the service during OS bootup. chef-client will start it.
  action [ :disable, :start ]
  supports :status => true, :restart => true

  notifies :create, resources("ruby_block[#{node[:hadoop][:namenode_service_name]}]"), :immediately
end

# In Namenode HA case, when trying to get safemode status,
# the primary namenode service wants to connect to standby namenode service which is waiting for primary namenode.
# Then deadlock occurs. So need to skip this step.
unless namenode_ha_enabled
  # run this regardless namenode is already started before bootstrapping or started by this recipe
  include_recipe "hadoop_cluster::wait_on_hdfs_safemode"
end

if namenode_ha_enabled
  # Register to provide primary namenode formatted
  if is_primary_namenode
    notify(node[:hadoop][:primary_namenode_format])
  else
    notify(node[:hadoop][:standby_namenode_format])
  end

  # Wait for standby namenode started
  wait_for(node[:hadoop][:standby_namenode_format], {"provides_service" => node[:hadoop][:standby_namenode_format], "facet_name" => node[:facet_name]} )

  # Start ZKFC service
  include_recipe "hadoop_cluster::zkfc"

  # Wait for all zkfc
  zkfc_count = all_nodes_count({"role" => "hadoop_namenode", "facet_name" => node[:facet_name]})
  wait_for(node[:hadoop][:zkfc_service_name], {"provides_service" => node[:hadoop][:zkfc_service_name], "facet_name" => node[:facet_name]}, true, zkfc_count)

  # setup keyless ssh between namenodes to support HDFS HA and automatic failover
  setup_keyless_ssh_for_user_on_role('root', 'hadoop_namenode')
end

if is_primary_namenode
  # initialize hdfs dirs after namenode is formatted and started,
  # and before jobtracker/resourcemanager is started.
  include_recipe "hadoop_cluster::bootstrap_hdfs_dirs"
end

# Start hmonitor ha service at the end of bootstrapping
if is_hortonworks_hmonitor_namenode_enabled
  start_ha_service node[:hadoop][:hmonitor_ha_service], true
end

# register with cluster_service_discovery
provide_service(node[:hadoop][:namenode_service_name])

clear_bootstrap_action
