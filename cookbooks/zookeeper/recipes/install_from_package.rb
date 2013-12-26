#
#   Copyright (c) 2012-2013 VMware, Inc. All Rights Reserved.
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

include_recipe "hadoop_common::add_repo"
include_recipe "hadoop_cluster::update_attributes"

#
# Install package
#
package node[:zookeeper][:package_name]

link "#{node[:zookeeper][:home_dir]}/conf" do
  action :delete
  only_if "test -L #{node[:zookeeper][:home_dir]}/conf"
end

directories = ['/var/lib/zookeeper', '/var/log/zookeeper', '/etc/zookeeper/']
directories.each do | directory_name |
  directory directory_name do
  recursive true
  action :delete
  end
end

directory "#{node[:zookeeper][:home_dir]}/conf" do
  owner "zookeeper"
  group "zookeeper"
  mode "0755"
end
