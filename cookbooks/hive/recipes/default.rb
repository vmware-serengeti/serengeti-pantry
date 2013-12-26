#
# Cookbook Name::       hive
# Description::         Base configuration for hive
# Recipe::              default
# Author::              Philip (flip) Kromer - Infochimps, Inc
#
# Copyright 2009, Opscode, Inc.
# Portions copyright © 2012-2013 VMware, Inc. All rights Reserved.
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

# we haven't added postgresql packages for Fedora in Serengeti internal yum repo yet, so skip installing hive components.
return if node[:platform] == "fedora"

include_recipe "java::sun"
include_recipe "hadoop_cluster::update_attributes"

# alias hive home dir
if is_pivotalhd_distro
  node.normal[:hive][:home_dir] = '/usr/lib/gphd/hive'
  node.normal[:hive][:conf_dir] = '/etc/gphd/hive/conf'
end
force_link("/usr/lib/hive", node[:hive][:home_dir])

user node[:hive][:user] do
  comment "A sample user for hive server"
  home  "/var/lib/hive"
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

# Install Hive
set_bootstrap_action(ACTION_INSTALL_PACKAGE, 'hive', true)
if node[:hadoop][:install_from_tarball] then
  include_recipe "hive::install_from_tarball"
else
  include_recipe "hive::install_from_package"
end

# alias hive conf dir
make_link("/usr/lib/hive/conf", node[:hive][:conf_dir])

update_hive_version

include_recipe "hive::postgresql_metastore"

#update hive-site.xml configuration items
update_hive_config

clear_bootstrap_action

