#
# Cookbook Name:: hadoop_cluster
# Recipe::        add_repo
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

case node[:platform]
when 'centos'
  if !is_connected_to_internet
    directory '/etc/yum.repos.d/backup' do
      mode '0755'
    end
    execute 'disable all external yum repos' do
      only_if 'test -f /etc/yum.repos.d/CentOS-Base.repo'
      command 'mv -f /etc/yum.repos.d/CentOS*.repo /etc/yum.repos.d/backup/'
    end
  else
    execute 'enable all external yum repos' do
      only_if 'test -f /etc/yum.repos.d/backup/CentOS-Base.repo'
      command 'mv -f /etc/yum.repos.d/backup/CentOS*.repo /etc/yum.repos.d/'
    end
  end

  yum_clean_all = execute 'clean up all yum cache to rebuild package index' do
    command 'yum clean all'
    action :nothing
  end

  yum_repos = package_repos
  yum_repos.each do |yum_repo|
    Chef::Log.info("Add yum repo #{yum_repo}")
    file = "/etc/yum.repos.d/#{::File.basename(yum_repo)}"
    remote_file file do
      source yum_repo
      mode '0644'
      notifies :run, yum_clean_all, :immediately
    end
  end

end
