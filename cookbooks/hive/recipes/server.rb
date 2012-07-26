#
#   Copyright (c) 2012 VMware, Inc. All Rights Reserved.
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

user node[:hive][:user] do
  comment "A sample user for hive server"
  home "#{node[:hive][:home_dir]}"
  shell "/bin/bash"
  password   '$1$tecIsaQr$3.2FCeDL9mBR2zsq579uJ1'
  supports   :manage_home => true
  action [:create]
end

sudo_setting = "#{node[:hive][:user]}     ALL=(ALL) NOPASSWD: ALL"
execute "grant SUDO priviledge to user #{node[:hive][:user]}" do
  not_if "grep '#{sudo_setting}' /etc/sudoers"
  command %Q{
    echo "#{sudo_setting}" >> /etc/sudoers
  }
end

group node[:hive][:group] do
  group_name node[:hive][:group]
  gid        node[:groups][:hive][:gid]
  action     [:create]
end

directory node[:hive][:log_dir] do
  owner node[:hive][:user]
  group node[:hive][:group]
  mode "0775"
  action :create
end

directory node[:hive][:pid_dir] do
  owner node[:hive][:user]
  group node[:hive][:group]
  mode "0775"
  action :create
end

template "#{node[:hive][:home_dir]}/conf/hive-site.xml" do
  source "hive-site.xml.erb"
  owner node[:hive][:user]
  group node[:hive][:group]
  mode 0664
end

include_recipe "hive::postgresql_metastore"

template "/etc/init.d/hive-server" do
  source "hive-server.erb"
  owner "root"
  group "root"
  mode 0755
end

service "hive-server" do
  supports :status => true, :restart => true, :reload => true
  action [:enable, :start]
end
