#
# Cookbook Name:: hadoop_cluster
# Recipe::        namenode
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
include_recipe "hadoop_cluster::wait_for_hdfs"

# Install
hadoop_package node[:hadoop][:packages][:namenode][:name]

# Regenerate Hadoop xml conf files with new Hadoop server address
include_recipe "hadoop_cluster::hadoop_conf_xml"

# for Bigtop Hadoop YARN packages (e.g. CDH4, Pivotal HD 1.0)
hadoop_dir = hadoop_home_dir
hdfs_dir = hadoop_hdfs_dir
force_link("#{hdfs_dir}/libexec", "#{hadoop_dir}/libexec") if hdfs_dir

# Format namenode
if is_primary_namenode
  include_recipe "hadoop_cluster::bootstrap_format_namenode"
else
  include_recipe "hadoop_cluster::bootstrap_format_standbynamenode"
end

## Launch NameNode service
resource_wait_for_namenode = resources(:execute => "wait_for_namenode")
set_bootstrap_action(ACTION_START_SERVICE, node[:hadoop][:namenode_service_name])

is_namenode_running = system("service #{node[:hadoop][:namenode_service_name]} status 1>2 2>/dev/null")
service "restart-#{node[:hadoop][:namenode_service_name]}" do
  service_name node[:hadoop][:namenode_service_name]
  supports :status => true, :restart => true

  subscribes :restart, resources("template[/etc/hadoop/conf/core-site.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/hdfs-site.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/hadoop-env.sh]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/log4j.properties]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/hadoop-metrics.properties]"), :delayed
  unless ['create', 'launch'].include?(node[:cluster_action])
    # When running 'cluster create' or 'cluster launch', new nodes are added into this cluster.
    # chef-client will only append new lines to /etc/hadoop/conf/topology.data (containing ip to rack mapping), and no existing lines are updated.
    # And when Namenode adds a new Datanode (having a new IP), it will lookup topology.data to find its rack info.
    # So there is no need to restart Namenode daemon in this case.
    subscribes :restart, resources("template[/etc/hadoop/conf/topology.data]"), :delayed
  end
  notifies :create, resources("ruby_block[#{node[:hadoop][:namenode_service_name]}]"), :immediately
  notifies :run, resource_wait_for_namenode, :immediately
end if is_namenode_running

service "start-#{node[:hadoop][:namenode_service_name]}" do
  service_name node[:hadoop][:namenode_service_name]

  # Do not starts the service to start at system boot time
  action [ :disable, :start ]
  supports :status => true, :restart => true

  notifies :create, resources("ruby_block[#{node[:hadoop][:namenode_service_name]}]"), :immediately
end

# run this regardless namenode is already started before bootstrapping or started by this recipe
run_in_ruby_block(resource_wait_for_namenode.name) { resource_wait_for_namenode.run_action(:run) }

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

  # copy rsa pub key to other namenode for hdfs HA to automatic failover
  if is_primary_namenode
    rsa_pub_key_conditions = {"facet_name" => node[:facet_name], "facet_index" => 1}
  else
    rsa_pub_key_conditions = {"facet_name" => node[:facet_name], "facet_index" => 0}
  end
  rsa_pub_key = rsa_pub_keys_of_user_for_condition("root", rsa_pub_key_conditions).first
  execute "copy rsa pub key" do
    user 'root'
    command %Q{
      if [ -e /root/.ssh/authorized_keys ]; then
        if [ ! grep '#{rsa_pub_key}' /root/.ssh/authorized_keys ]; then
          echo '#{rsa_pub_key}' >> /root/.ssh/authorized_keys
        fi
      else
        echo '#{rsa_pub_key}' > /root/.ssh/authorized_keys
      fi
    }
  end

end

if is_primary_namenode
  # initialize hdfs dirs after namenode is formatted and started,
  # and before jobtracker/resourcemanager is started.
  include_recipe "hadoop_cluster::bootstrap_hdfs_dirs"
end

# register with cluster_service_discovery
provide_service(node[:hadoop][:namenode_service_name])

# install Hortonworks HMonitor vSphere HA (see http://hortonworks.com/thankyou-hdp12-hakit-vmw/?mdl=13577&ao=0&lnk=0)
if is_hortonworks_hmonitor_namenode_enabled
  hadoop_ha_package "namenode"
  enable_ha_service "hmonitor-namenode-monitor"
end

clear_bootstrap_action(true)