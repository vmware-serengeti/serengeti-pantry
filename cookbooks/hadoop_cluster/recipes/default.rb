#
# Cookbook Name:: hadoop_cluster
# Recipe::        default
#

#
# Copyright 2009, Opscode, Inc.
# Portions Copyright (c) 2012-2013 VMware, Inc. All Rights Reserved.
#
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

include_recipe "java"

class Chef::Recipe; include HadoopCluster ; end

# place at the startpoint of cookbook
node[:bootstrap_time] = Time.now

# Setup package repository
include_recipe "hadoop_common::add_repo"
# Update some node attributes
include_recipe "hadoop_cluster::update_attributes"

#
# Hadoop users and group
#

group 'hdfs' do gid 302 ; action [:create] ; end
user 'hdfs' do
  comment    'Hadoop HDFS User'
  uid        302
  group      'hdfs'
  home       "/var/lib/hdfs"
  shell      "/bin/bash"
  password   nil
  supports   :manage_home => true
  action     [:create, :manage]
end

group 'mapred' do gid 303 ; action [:create] ; end
user 'mapred' do
  comment    'Hadoop Mapred Runner'
  uid        303
  group      'mapred'
  home       "/var/lib/mapred"
  shell      "/bin/bash"
  password   nil
  supports   :manage_home => true
  action     [:create, :manage]
end

group 'yarn' do gid 304 ; action [:create] ; end
user 'yarn' do
  comment    'Hadoop Yarn User'
  uid        304
  group      'yarn'
  home       "/var/lib/yarn"
  shell      "/bin/bash"
  password   nil
  supports   :manage_home => true
  action     [:create, :manage]
end

group 'hadoop' do
  group_name 'hadoop'
  gid         node[:groups]['hadoop'][:gid]
  action      [:create, :manage]
  members     ['hdfs', 'mapred', 'yarn']
end

user 'webuser' do
  comment    'Hadoop Web Server User'
  uid        305
  group      'hadoop'
  home       "/var/lib/webuser"
  shell      "/bin/bash"
  password   nil
  supports   :manage_home => true
  action     [:create, :manage]
end

# Create the group hadoop uses to mean 'can act as filesystem root'
group 'supergroup' do
  group_name 'supergroup'
  gid        node[:groups]['supergroup'][:gid]
  action     [:create]
  members    ['hdfs', 'root']
end

# Generate ssh rsa keypair for user root
generate_ssh_rsa_keypair('root', '/root')

#
# Hadoop packages
#

hadoop_package node[:hadoop][:packages][:hadoop][:name]
check_hadoop_daemon_sh
