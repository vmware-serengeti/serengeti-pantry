#
# Cookbook Name:: hadoop_cluster
# Recipe:: add_repo
#
# Copyright 2012, VMware, Inc.
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
    command %q{
      rpm --import http://archive.cloudera.com/cdh4/redhat/5/x86_64/cdh/RPM-GPG-KEY-cloudera
      wget -O /etc/yum.repos.d/cloudera-cdh4.repo  http://archive.cloudera.com/cdh4/redhat/5/x86_64/cdh/cloudera-cdh4.repo
    }
  end
else
  execute "adding cloudera-cdh3 rpm repositry" do
    command %Q{
      rpm --import #{node[:hadoop][:distro][:cdh3][:repository][:key_url]}
      wget -O /etc/yum.repos.d/#{node[:hadoop][:distro][:cdh3][:repository][:repo_name]} #{node[:hadoop][:distro][:cdh3][:repository][:repo_url]}
    }
  end
end