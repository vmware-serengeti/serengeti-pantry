#
# Cookbook Name:: hadoop_cluster
# Recipe::        cluster_conf
#

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

class Chef::Recipe; include HadoopCluster ; end

# Hadoop xml configuration files in $HADDOP_HOME/conf/
include_recipe "hadoop_cluster::hadoop_conf_xml" unless is_namenode or is_jobtracker or is_secondarynamenode or is_journalnode

# Add symlinks to HADOOP_HOME
force_link("/usr/lib/hadoop", "/usr/lib/#{node[:hadoop][:hadoop_handle]}")

# Make hadoop logs live on /mnt/hadoop or user defined log dir
hadoop_log_dir = hadoop_log_dir_conf || local_hadoop_log_dir
make_hadoop_dir(hadoop_log_dir, 'hdfs', '0775')
force_link("/var/log/hadoop", hadoop_log_dir )
force_link("/var/log/hadoop-yarn", yarn_system_log_dir ) if is_hadoop_yarn?
force_link("/var/log/#{node[:hadoop][:hadoop_handle]}", hadoop_log_dir )

# Make hadoop point to /var/run for pids
make_hadoop_dir("/var/run/#{node[:hadoop][:hadoop_handle]}", 'root', '0775')
force_link('/var/run/hadoop', "/var/run/#{node[:hadoop][:hadoop_handle]}")

make_hadoop_dir(hadoop_home_dir + '/logs', 'root', '0775')

# CDH, Greenplum HD, Hortonworks all use Bigtop to build and deliver Hadoop rpm/apt packages
file = '/etc/default/bigtop-utils'
execute "Set JAVA_HOME for Bigtop hadoop packages" do
  only_if { File.exists?(file) }
  not_if "grep '^export JAVA_HOME' #{file}"
  command %Q{
cat <<EOF >> #{file}
# detect JAVA_HOME
. /etc/profile
. /etc/environment
export JAVA_HOME
EOF
  }
end

# Fix '-jvm server' option in bin/yarn and bin/hdfs. Have no idea why hadoop-0.23 add this option.
%w[bin/yarn bin/hdfs].each do |file|
  execute "fix '-jvm server' option in bin/yarn and bin/hdfs" do
    only_if do File.exists?("/usr/lib/hadoop/#{file}") end
    command %Q{sed -i -e 's|-jvm server|-server|' /usr/lib/hadoop/#{file}}
  end
end

# Set HADOOP_ROOT_LOGGER
logger = node['cluster_configuration']['hadoop']['log4j.properties']['hadoop.root.logger'] rescue logger = "INFO,RFA"
file = path_of_hadoop_daemon_sh
execute "set HADOOP_ROOT_LOGGER to hadoop.root.logger value in log4j.properties" do
  only_if { File.exist?(file) }
  command %Q{sed -i -e 's|^export HADOOP_ROOT_LOGGER=.*|export HADOOP_ROOT_LOGGER=#{logger}|' #{file}}
end

# Set SLEEP_TIME
execute "Set SLEEP_TIME longer enough for the hadoop service process to stop completely" do
  command %Q{
    for service in /etc/init.d/hadoop-*; do
      sed -i -e 's|SLEEP_TIME=.*|SLEEP_TIME=#{node[:hadoop][:service_stop_time]}|' $service
    done
    true
  }
end
