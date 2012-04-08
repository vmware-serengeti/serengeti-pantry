#
# Cookbook Name:: zookeeper
# Recipe:: default
#
# Copyright 2010, Infochimps, Inc.
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

# Users and Groups
group 'zookeeper' do gid node[:groups]['zookeeper'][:gid] ; action [:create] ; end
user 'zookeeper' do
  comment    'Hadoop Zookeeper Daemon'
  uid        node[:users ]['zookeeper'][:uid]
  group      node[:groups]['zookeeper'][:gid]
  home       "/var/lib/zookeeper"
  shell      "/bin/bash"
  password   nil
  supports   :manage_home => true
  action     [:create, :manage]
end

# Install
package node[:zookeeper][:zookeeper_package_name]

# Create directory
directory "/var/lib/zookeeper" do
  owner      "zookeeper"
  group      "zookeeper"
  mode       "0755"
  action     :create
  recursive  true
end
