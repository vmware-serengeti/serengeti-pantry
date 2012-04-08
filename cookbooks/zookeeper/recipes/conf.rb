#
# Cookbook Name:: zookeeper
# Recipe:: conf
#
# Copyright 2012, VMware, Inc.
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

#
# Generate Zookeeper configuration files
#

# Get Zookeeper servers address 
total_count = node[:zookeeper][:cluster_servers_count]
existing_count = 0
while true do
  # Sort by IP instead of service_registed_timestamp to assign myid correctly. 
  # If sorting by service_registed_timestamp, re-registering the service (with a new timestamp) will change the existing index of zookeeper servers.
  zookeeper_servers_ips = all_provider_private_ips(node[:zookeeper][:service_registry_name]).sort 
  existing_count = zookeeper_servers_ips.count
  break if existing_count >= total_count
  Chef::Log.info("Waiting for the number #{existing_count + 1} zookeeper server to join in. The Zookeeper cluster is configured to have #{total_count} Zookeeper servers.")
  sleep 5
end

myid = zookeeper_servers_ips.find_index( private_ip_of node )

template_variables = {
  :zookeeper_servers_ips   => zookeeper_servers_ips,
  :myid                   => myid,
  :zookeeper_data_dir     => node[:zookeeper][:data_dir],
  :zookeeper_max_client_connections => node[:zookeeper][:max_client_connections],
}
Chef::Log.debug template_variables.inspect
%w[ zoo.cfg ].each do |conf_file|
  template "/etc/zookeeper/conf/#{conf_file}" do
    owner "root"
    mode "0644"
    variables(template_variables)
    source "#{conf_file}.erb"
  end
end

template "/var/lib/zookeeper/myid" do
 owner "zookeeper"
 mode "0644"
 variables(template_variables)
 source "myid.erb"
end
