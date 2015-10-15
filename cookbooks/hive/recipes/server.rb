#
#   Copyright (c) 2012-2014 VMware, Inc. All Rights Reserved.
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

return if node[:platform] == "fedora"

# Hive 1.0+ uses hive-server2 instead of hive-server
if is_bigtop_hadoop2_distro and distro_version.to_f >= 1
  node.default[:hadoop][:packages][:hive_server][:name] = 'hive-server2'
  node.default[:hadoop][:hive_service_name] = 'hive-server2'
end

if node[:hadoop][:install_from_tarball]
  template '/etc/init.d/hive-server' do
    source 'hive-server.erb'
    owner 'root'
    group 'root'
    mode '0755'
  end
else
  package node[:hadoop][:packages][:hive_server][:name]
end

# CDH 5.4 contains Hive 1.1
if is_cdh4_distro and distro_version.to_f >= 5.4
  execute 'fix hive server 2 issue in CDH 5.4' do
    not_if 'grep -q hiveserver2 /etc/init.d/hive-server'
    command "sed -i 's|--service hiveserver |--service hiveserver2 |' /etc/init.d/hive-server"
  end
end

service "#{node[:hadoop][:hive_service_name]}" do
  supports :status => true, :restart => true, :reload => true
  action [:enable, :start]
end

#FIXME this is a bug in Pivotal HD 1.0 alpha and CDH4.1.2+
execute 'start hive server due to hive service status always returns 0' do
  only_if "service #{node[:hadoop][:hive_service_name]} status | grep 'not running'"
  command "service #{node[:hadoop][:hive_service_name]} start"
end
