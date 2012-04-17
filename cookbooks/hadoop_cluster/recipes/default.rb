#
# Cookbook Name:: hadoop
# Recipe:: default
#
# Copyright 2009, Opscode, Inc.
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

#
# Cloudera repo
#
=begin
# Dummy apt-get resource, will only be run if the apt repo requires updating
execute("apt-get -y update"){ action :nothing }

# Add cloudera package repo
template "/etc/apt/sources.list.d/cloudera.list" do
  owner "root"
  mode "0644"
  source "sources.list.d-cloudera.list.erb"
end
# Get the archive key for cloudera package repo
execute "curl -s http://archive.cloudera.com/debian/archive.key | apt-key add -" do
  not_if "apt-key export 'Cloudera Apt Repository' | grep 'BEGIN PGP PUBLIC KEY'"
  notifies :run, resources("execute[apt-get -y update]"), :immediately
end
=end

if is_hadoop_yarn? then
  execute "adding cloudera-cdh4 rpm repositry" do
    not_if "test -f /etc/yum.repos.d/cloudera-cdh4.repo"
    command %q{
      rpm --import http://archive.cloudera.com/cdh4/redhat/5/x86_64/cdh/RPM-GPG-KEY-cloudera
      wget -O /etc/yum.repos.d/cloudera-cdh4.repo  http://archive.cloudera.com/cdh4/redhat/5/x86_64/cdh/cloudera-cdh4.repo
    }
  end
else
  execute "adding cloudera-cdh3 rpm repositry" do
    not_if "test -f /etc/yum.repos.d/cloudera-cdh3.repo"
    command %q{
      rpm --import http://archive.cloudera.com/redhat/cdh/RPM-GPG-KEY-cloudera
      wget -O /etc/yum.repos.d/cloudera-cdh3.repo  http://archive.cloudera.com/redhat/cdh/cloudera-cdh3.repo
    }
  end
end

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

group 'hadoop' do
  group_name 'hadoop'
  gid         node[:groups]['hadoop'][:gid]
  action      [:create, :manage]
  members     ['hdfs', 'mapred', 'yarn', 'webuser']
end

# Create the group hadoop uses to mean 'can act as filesystem root'
group 'supergroup' do
  group_name 'supergroup'
  gid        node[:groups]['supergroup'][:gid]
  action     [:create]
end

#
# Hadoop packages
#

hadoop_package nil

