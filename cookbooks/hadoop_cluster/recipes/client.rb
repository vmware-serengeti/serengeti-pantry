#
# Cookbook Name:: hadoop_cluster
# Recipe::        client
#

#
#   Copyright (c) 2012 VMware, Inc. All Rights Reserved.
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

#
# Defines a machine acting as a Hadoop Client to submit Hadoop jobs
#

# Must have ruby-shadow installed for password support when creating a user.
gem_package "ruby-shadow" do
  action :install
end

# Create a user
# Check how to use Resource User: http://wiki.opscode.com/display/chef/Resources#Resources-User
username = node[:hadoop][:client][:admin][:username]
user username do
  comment    'A sample user for submitting Hadoop jobs'
  home       "/var/lib/#{username}"
  shell      "/bin/bash"
  password   '$1$tecIsaQr$3.2FCeDL9mBR2zsq579uJ1'
  supports   :manage_home => true
  action     [:create]
end

sudo_setting = "#{username}     ALL=(ALL) NOPASSWD: ALL"
execute "grant SUDO priviledge to user #{username}" do
  not_if "grep '#{sudo_setting}' /etc/sudoers"
  command %Q{
    echo "#{sudo_setting}" >> /etc/sudoers
  }
end

