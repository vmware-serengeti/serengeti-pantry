#
# Cookbook Name:: zookeeper
# Recipe::        default
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

include_recipe "java::sun"
include_recipe "hadoop_common::mount_disks"

jvm_default_option = "-Xmx512m"

group "zookeeper" do
end

user "zookeeper" do
  gid "zookeeper"
end

include_recipe "install_from"

# Load distro repository info
current_distro = data_bag_item("hadoop_distros", node[:hadoop][:distro_name])
tarball_url = current_distro['zookeeper']
unless ::File.exists?("#{node[:zookeeper][:home_dir]}")
  set_bootstrap_action(ACTION_INSTALL_PACKAGE, 'zookeeper')
end

install_from_release('zookeeper') do
  release_url   tarball_url
  home_dir      node[:zookeeper][:home_dir]
  version       node[:zookeeper][:version]
  action        [:install]
  not_if { ::File.exists?("#{node[:zookeeper][:home_dir]}") }
end

# link Zookeeper data dir and log dir to the mounted data disk to get larger disk space
disk_dir = disks_mount_points[0]
if disk_dir
  dirs = { '/var/lib/zookeeper' => 'zookeeper/data', '/var/log/zookeeper' => 'zookeeper/log' }
  dirs.map do |src, des|
    target = "#{disk_dir}/#{des}"
    directory target do
      owner "zookeeper"
      group "zookeeper"
      mode "0755"
      recursive true
    end

    link src do
      to target
    end
  end
end

dirs = ["/var/run/zookeeper"]
dirs += ["/var/lib/zookeeper", "/var/log/zookeeper"] unless disk_dir
dirs.each do |dir|
  directory dir do
    owner "zookeeper"
    group "zookeeper"
    mode "0755"
  end
end

link "/etc/zookeeper" do
  to node[:zookeeper][:home_dir] + "/conf"
end

zk_servers = search(:node, "cluster_name:#{node[:cluster_name]} AND role:zookeeper")
zk_servers.sort! { |a, b| a.name <=> b.name }
Chef::Log.info("Zookeeper servers in cluster are: #{zk_servers.inspect}")
quorum = zk_servers.collect { |n| "#{n[:provision][:ip_address]}:#{node[:zookeeper][:client_port]}" }
myid = zk_servers.collect { |n| n[:provision][:ip_address] }.index(node[:provision][:ip_address])

%w[ zoo.cfg log4j.properties ].each do |file|
  template "/etc/zookeeper/#{file}" do
    owner "zookeeper"
    source "#{file}.erb"
    mode "0644"
    variables(:servers => zk_servers)
  end
end

java_conf = node['cluster_configuration']['zookeeper']['java.env'] || {} rescue {}
jvm_option =  java_conf['jvm_option'] || jvm_default_option

template "/etc/zookeeper/java.env" do
  source "java.env.erb"
  mode "0755"
  owner "zookeeper"
  group "zookeeper"
  variables(:jvm_option => jvm_option)
end

template "/var/lib/zookeeper/myid" do
  source "myid.erb"
  owner "zookeeper"
  group "zookeeper"
  variables(:myid => myid)
end

template "#{node[:zookeeper][:home_dir]}/bin/zkEnv.sh" do
  source "zkEnv.sh.erb"
  owner "zookeeper"
  group "zookeeper"
  mode  "0755"
end

template "/etc/init.d/zookeeper-server" do
  source "zookeeper-server.erb"
  owner "root"
  group "root"
  mode  "0755"
end

# This piece of code is for Hontonworks distro only(zookeeper 3.3.4)
bash "Remove invalid nc parameter in zkServer.sh" do
  code "sed -i 's/nc -q 1/nc/' #{node[:zookeeper][:home_dir]}/bin/zkServer.sh"
end

## Launch Service
set_bootstrap_action(ACTION_START_SERVICE, node[:zookeeper][:zookeeper_service_name])

is_zookeeper_running = system("service #{node[:zookeeper][:zookeeper_service_name]} status")
service "restart-#{node[:zookeeper][:zookeeper_service_name]}" do
  service_name node[:zookeeper][:zookeeper_service_name]
  supports :status => true, :restart => true

  subscribes :restart, resources("template[/etc/zookeeper/zoo.cfg]"), :delayed
  subscribes :restart, resources("template[/etc/zookeeper/log4j.properties]"), :delayed
  subscribes :restart, resources("template[/etc/zookeeper/java.env]"), :delayed
  subscribes :restart, resources("template[#{node[:zookeeper][:home_dir]}/bin/zkEnv.sh]"), :delayed
  notifies :create, resources("ruby_block[#{node[:zookeeper][:zookeeper_service_name]}]"), :immediately
end if is_zookeeper_running

service "start-#{node[:zookeeper][:zookeeper_service_name]}" do
  service_name node[:zookeeper][:zookeeper_service_name]
  action [ :enable, :start ]
  supports :status => true, :restart => true

  notifies :create, resources("ruby_block[#{node[:zookeeper][:zookeeper_service_name]}]"), :immediately
end

# Register with cluster_service_discovery
provide_service(node[:zookeeper][:zookeeper_service_name], { :quorum => quorum, :id => myid })
