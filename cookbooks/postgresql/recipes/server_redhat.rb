#
# Cookbook Name:: postgresql
# Recipe:: server
#
# Author:: Joshua Timberman (<joshua@opscode.com>)
# Author:: Lamont Granquist (<lamont@opscode.com>)
# Copyright 2009-2011, Opscode, Inc.
# Portions Copyright (c) 2012-2013 VMware, Inc. All Rights Reserved.
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

# Create a group and user like the package will.
# Otherwise the templates fail.

group "postgres" do
  gid 26
end

user "postgres" do
  shell "/bin/bash"
  comment "PostgreSQL Server"
  home "/var/lib/pgsql"
  gid "postgres"
  system true
  uid 26
  supports :manage_home => false
end

case node.platform
when "redhat", "centos", "scientific"
  case
  when node.platform_version.to_f >= 5.0
    package "postgresql-server"
  else
    package "postgresql#{node['postgresql']['version'].split('.').join}-server"
  end
when "fedora","suse"
  package "postgresql-server"
end

template "/etc/init.d/postgresql" do
  source "postgresql.erb"
  owner "root"
  group "root"
  mode "0755"
end

execute "postgresql initdb" do
  not_if { File.exists?(File.join(node[:postgresql][:dir], "PG_VERSION")) }
  command %Q{
    service postgresql initdb
  }
  action :run
end

template "#{node[:postgresql][:dir]}/postgresql.conf" do
  source "postgresql.conf.erb"
  owner "postgres"
  group "postgres"
  mode "0600"
end

service "postgresql" do
  supports :restart => true, :status => true, :reload => true
  action [:enable, :start]
end
