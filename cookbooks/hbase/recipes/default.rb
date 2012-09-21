#
# Cookbook Name:: hbase
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

group "hbase" do
end

user "hbase" do
  gid "hbase"
end

include_recipe "install_from"

# Load distro repository info
current_distro = data_bag_item("hadoop_distros", node[:hadoop][:distro_name])
tarball_url = current_distro['hbase']
unless ::File.exists?("#{node[:hbase][:home_dir]}")
  set_bootstrap_action(ACTION_INSTALL_PACKAGE, 'hbase')
end

install_from_release('hbase') do
  release_url   tarball_url
  home_dir      node[:hbase][:home_dir]
  version       node[:hbase][:version]
  action        [:install]
  has_binaries  [ 'bin/hbase' ]
  not_if { ::File.exists?("#{node[:hbase][:home_dir]}") }
end

["/var/log/hbase", "/var/run/hbase", "/etc/hbase"].each do |dir|
  directory dir do
    owner "hbase"
    group "hbase"
    mode 0755
  end
end

hbase_conf_dir = "/etc/hbase/conf"
link hbase_conf_dir do
  to node[:hbase][:home_dir] + "/conf"
end

hbase_hdfs_home = "hdfs://#{namenode_address}:#{namenode_port}#{node[:hbase][:hdfshome]}"
zk_service_name = node[:hbase][:zookeeper_service_name]
zk_service_provider = provider_for_service(zk_service_name)
zk_quorum = zk_service_provider[:provides_service][zk_service_name][:quorum]

template_variables = {
  :hbase_hdfs_home => hbase_hdfs_home,
  :zookeeper_quorum => zk_quorum.join(",")
}

%w[ hbase-site.xml hbase-env.sh ].each do |file|
  template "#{hbase_conf_dir}/#{file}" do
    owner "hbase"
    mode file.end_with?('.sh') ? "0755" : "0644"
    variables(template_variables)
    source "#{file}.erb"
  end
end

%w[ hbase-daemon.sh ].each do |file|
  template "#{node[:hbase][:home_dir]}/bin/#{file}" do
    owner "hbase"
    mode file.end_with?('.sh') ? "0755" : "0644"
    source "#{file}.erb"
  end
end
