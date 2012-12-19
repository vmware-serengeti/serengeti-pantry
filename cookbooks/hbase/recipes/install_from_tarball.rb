#
# Cookbook Name:: hbase
# Recipe::        install_from_tarball
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
  not_if{ ::File.exists?("#{node[:hbase][:home_dir]}") }
end

