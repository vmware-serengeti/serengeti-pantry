#
#   Portions Copyright (c) 2012-2013 VMware, Inc. All Rights Reserved.
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

include_recipe "hadoop_cluster"

# Install
hadoop_package node[:hadoop][:packages][:zkfc][:name]

if is_primary_namenode
  # Format ZK
  include_recipe "hadoop_cluster::bootstrap_format_zk"
else
  # Wait for primary zkfc started
  wait_for(node[:hadoop][:zkfc_service_name], {"provides_service" => node[:hadoop][:zkfc_service_name], "facet_name" => node[:facet_name]})
end

# Launch service
set_bootstrap_action(ACTION_START_SERVICE, node[:hadoop][:zkfc_service_name])

is_zkfc_running = system("service #{node[:hadoop][:zkfc_service_name]} status 1>2 2>/dev/null")
service "restart-#{node[:hadoop][:zkfc_service_name]}" do
  service_name node[:hadoop][:zkfc_service_name]
  supports :status => true, :restart => true

  subscribes :restart, resources("template[/etc/hadoop/conf/core-site.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/hdfs-site.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/hadoop-env.sh]"), :delayed
  subscribes :restart, resources("template[/etc/hadoop/conf/log4j.properties]"), :delayed
  notifies :create, resources("ruby_block[#{node[:hadoop][:zkfc_service_name]}]"), :immediately
end if is_zkfc_running

service "start-#{node[:hadoop][:zkfc_service_name]}" do
  service_name node[:hadoop][:zkfc_service_name]
  action [ :disable, :start ]
  supports :status => true, :restart => true

  notifies :create, resources("ruby_block[#{node[:hadoop][:zkfc_service_name]}]"), :immediately
end

# register with cluster_service_discovery
provide_service(node[:hadoop][:zkfc_service_name])

clear_bootstrap_action