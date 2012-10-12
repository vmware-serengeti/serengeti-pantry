#
# Cookbook Name:: hbase
# Recipe::        master
#

#
#   Portions Copyright (c) 2012 VMware, Inc. All Rights Reserved.
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

include_recipe "hadoop_cluster" # install the hadoop binary which will be used to wait for hdfs in case HBase is installed without Hadoop
include_recipe "hbase"

hbase_conf_dir = "/etc/hbase/conf"

%w[ hbase-env-master.sh ].each do |file|
  template "#{hbase_conf_dir}/#{file}" do
    owner "hbase"
    mode "0755"
    source "#{file}.erb"
  end
end

%w[ hbase-master ].each do |conf_file|
  template "/etc/init.d/#{conf_file}" do
    owner "root"
    mode "0755"
    source "#{conf_file}.erb"
  end
end

# when starting HBase Master daemon, it requires at least 1 datanode to replicate hbase.version,
# so wait until HDFS is ready.
include_recipe "hadoop_cluster::wait_for_hdfs"
wait_for_hdfs = resources(:ruby_block => "wait_for_hdfs")
run_in_ruby_block(wait_for_hdfs.name) { wait_for_hdfs.run_action(:create) }

## Launch service
set_bootstrap_action(ACTION_START_SERVICE, node[:hbase][:master_service_name])

is_master_running = system("service #{node[:hbase][:master_service_name]} status")
service "restart-#{node[:hbase][:master_service_name]}" do
  service_name node[:hbase][:master_service_name]
  supports :status => true, :restart => true

  subscribes :restart, resources("template[/etc/hbase/conf/hbase-site.xml]"), :delayed
  subscribes :restart, resources("template[/etc/hbase/conf/hbase-env.sh]"), :delayed
  subscribes :restart, resources("template[/etc/hbase/conf/hbase-env-master.sh]"), :delayed
  subscribes :restart, resources("template[/etc/hbase/conf/log4j.properties]"), :delayed
  notifies :create, resources("ruby_block[#{node[:hbase][:master_service_name]}]"), :immediately
end if is_master_running

service "start-#{node[:hbase][:master_service_name]}" do
  service_name node[:hbase][:master_service_name]
  action [ :enable, :start ]
  supports :status => true, :restart => true

  notifies :create, resources("ruby_block[#{node[:hbase][:master_service_name]}]"), :immediately
end

# Register with cluster_service_discovery
provide_service(node[:hbase][:master_service_name])
