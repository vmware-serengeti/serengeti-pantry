#
# Cookbook Name:: hbase
# Recipe::        default
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

include_recipe "java::sun"
include_recipe "hadoop_common::pre_run"
include_recipe "hadoop_cluster::hadoop_conf_xml"

# alias home dir
if is_pivotalhd_distro
  node.normal[:hbase][:home_dir] = '/usr/lib/gphd/hbase'
  node.normal[:hbase][:conf_dir] = '/etc/gphd/hbase/conf'
end
force_link("/usr/lib/hbase", node[:hbase][:home_dir])

group "hbase" do
end

user "hbase" do
  gid "hbase"
  shell "/bin/bash"
  password nil
end

ulimit_nofile = 32768
ulimit_nproc = 32000

def get_root_dir namespace
  "hdfs://#{namespace}#{node[:hbase][:hdfshome]}"
end

def set_sys_limit desc, user, ulimit_type, ulimit_value
  bash desc do
    not_if "egrep -q '#{user}.*#{ulimit_type}.*#{ulimit_value}' /etc/security/limits.conf"
    code <<EOF
      egrep -q '#{user}.*#{ulimit_type}' || ( echo '#{user} - #{ulimit_type}' >> /etc/security/limits.conf )
      sed -i "s/#{user}.*-.*#{ulimit_type}.*/#{user} - #{ulimit_type} #{ulimit_value}/" /etc/security/limits.conf
EOF
  end
end

set_sys_limit "Increase maximum num of open files ulimit", "@hbase", "nofile", ulimit_nofile
set_sys_limit "Increase maximum num of processes ulimit", "@hbase", "nproc", ulimit_nproc

set_bootstrap_action(ACTION_INSTALL_PACKAGE, 'hbase', true)

if is_install_from_tarball then
  include_recipe "hbase::install_from_tarball"
else
  include_recipe "hbase::install_from_package"
end

# link HBase log dir to the mounted data disk to get larger disk space
disk_dir = disks_mount_points[0]
if disk_dir
  dirs = { '/var/log/hbase' => 'hbase/log' }
  dirs.map do |src, des|
    target = "#{disk_dir}/#{des}"
    directory target do
      owner "hbase"
      group "hbase"
      mode  "0755"
      recursive true
    end
    force_link src, target
  end
end

dirs = ["/var/run/hbase", "/etc/hbase"]
dirs += ["/var/log/hbase"] unless disk_dir
dirs.each do |dir|
  directory dir do
    owner "hbase"
    group "hbase"
    mode  "0755"
  end
end

# Different Hadoop distro may have different conf dir. We will link '/etc/hbase/conf' to it.
make_link("#{node[:hbase][:home_dir]}/conf", node[:hbase][:conf_dir])
hbase_conf_dir = "/etc/hbase/conf"
link hbase_conf_dir do
  to node[:hbase][:conf_dir]
  not_if {File.exist?(hbase_conf_dir)} # to be compatible with CDH4
end

valid_namespaces_map = {}
default_namespace = ''
nn_port = namenode_port
if node[:hadoop][:cluster_has_hdfs_ha_or_federation]
  # map valid namespace name to all all its addresses and facet
  namenode_facet_addresses.each do |facet_addresses|
    facet_addresses.each do |facet, addresses|
      if addresses.length == 1
        valid_namespaces_map["#{addresses[0]}:#{nn_port}"] = addresses << facet
      else
        valid_namespaces_map[facet] = addresses << facet
      end
    end
  end

  # the default namespace, just select the first namespace
  if node[:hadoop][:cluster_has_only_federation] or namenode_facet_addresses[0][namenode_facet_names[0]].length == 1
    default_namespace = namenode_facet_addresses[0][namenode_facet_names[0]][0] + ":#{nn_port}"
  else
    default_namespace = namenode_facet_names[0]
  end
else
  default_namespace = namenode_address + ":#{nn_port}"
  valid_namespaces_map[default_namespace] = [default_namespace]
end

matched_namespace = nil
matched_pattern = ''
# try to guess a valid namespace name if user defined hbase.rootdir attr
conf = node['cluster_configuration']['hbase']['hbase-site.xml'] || {} rescue {}
if !conf['hbase.rootdir'].nil?
  user_defined_namespace = conf['hbase.rootdir']
  valid_namespaces_map.each do |namespace, patterns|
    patterns.each do |pattern|
      if user_defined_namespace.include? pattern and pattern.length > matched_pattern.length
        matched_pattern = pattern
        matched_namespace = namespace
      end
    end
  end
end

namespace = matched_namespace || default_namespace
hbase_hdfs_home = get_root_dir(namespace)

zk_quorum = zookeepers_quorum

# get zookeeper_session_timeout to be used in hbase-daemon.sh
zookeeper_session_timeout = node['cluster_configuration']['hbase']['hbase-site.xml']['zookeeper.session.timeout'] rescue nil
zookeeper_session_timeout ||= node[:hbase][:zookeeper_session_timeout]
zookeeper_session_timeout = zookeeper_session_timeout.to_i / 1000 + 120 # convert to seconds, and plus extra 2 minutes

template_variables = {
  :hbase_hdfs_home => hbase_hdfs_home,
  :zookeeper_quorum => zk_quorum,
  :zookeeper_session_timeout => zookeeper_session_timeout,
  :http_address => fqdn_of_hdfs_network(node),
  :bind_interface => device_of_hdfs_network(node),
  :is_version_1_0_0_0 => is_version_1_0_0_0?
}

%w[ hbase-site.xml hbase-env.sh log4j.properties ].each do |file|
  template "#{hbase_conf_dir}/#{file}" do
    owner "hbase"
    mode file.end_with?('.sh') ? "0755" : "0644"
    source "#{file}.erb"
    variables(template_variables)
  end
end

%w[ hbase-daemon.sh ].each do |file|
  template "#{node[:hbase][:home_dir]}/bin/#{file}" do
    owner "hbase"
    mode file.end_with?('.sh') ? "0755" : "0644"
    source "#{file}.erb"
    variables(template_variables)
  end
end

wait_for_zookeepers_service

clear_bootstrap_action
