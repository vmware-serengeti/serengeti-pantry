#
# Cookbook Name:: hbase
# Recipe::        regionserver
#

#
#   Portions Copyright (c) 2012-2013 VMware, Inc. All Rights Reserved.
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

include_recipe "hadoop_cluster"
include_recipe "hbase"

hbase_conf_dir = "/etc/hbase/conf"

%w[ hbase-env-regionserver.sh ].each do |file|
  template "#{hbase_conf_dir}/#{file}" do
    owner "hbase"
    mode "0755"
    source "#{file}.erb"
  end
end

%w[ hbase-regionserver ].each do |conf_file|
  template "/etc/init.d/#{conf_file}" do
    owner "root"
    mode "0755"
    source "#{conf_file}.erb"
  end
end

log = 'wait for HBase Master daemon to be ready'
run_in_ruby_block(log) do
  Chef::Log.info(log)
  provider_for_service(node[:hbase][:master_service_name])
end

## Launch service
set_bootstrap_action(ACTION_START_SERVICE, node[:hbase][:region_service_name])

is_regionserver_running = system("service #{node[:hbase][:region_service_name]} status")
service "restart-#{node[:hbase][:region_service_name]}" do
  service_name node[:hbase][:region_service_name]
  supports :status => true, :restart => true

  subscribes :restart, resources("template[/etc/hbase/conf/hbase-site.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hbase/conf/hbase-env.sh]"), :delayed
  subscribes :restart, resources("template[/etc/hbase/conf/hbase-env-regionserver.sh]"), :delayed
  subscribes :restart, resources("template[/etc/hbase/conf/log4j.properties]"), :delayed
  notifies :create, resources("ruby_block[#{node[:hbase][:region_service_name]}]"), :immediately
end if is_regionserver_running

service "start-#{node[:hbase][:region_service_name]}" do
  service_name node[:hbase][:region_service_name]
  action [ :enable, :start ]
  supports :status => true, :restart => true

  notifies :create, resources("ruby_block[#{node[:hbase][:region_service_name]}]"), :immediately
end

# Register with cluster_service_discovery
provide_service(node[:hbase][:region_service_name])

clear_bootstrap_action