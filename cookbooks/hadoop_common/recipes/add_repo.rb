#
# Cookbook Name:: hadoop_common
# Recipe::        add_repo
#

#
#   Copyright (c) 2012-2013 VMware, Inc. All Rights Reserved.
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
when 'centos', 'redhat'
  prefix = node[:platform] == 'centos' ? 'CentOS' : 'rhel'
  if !is_connected_to_internet
    directory '/etc/yum.repos.d/backup' do
      mode '0755'
    end
    file = "/etc/yum.repos.d/#{prefix}*.repo"
    execute 'disable all standard yum repos' do
      only_if "ls #{file}"
      command "mv -f #{file} /etc/yum.repos.d/backup/; rm -rf /etc/yum.repos.d/*.repo"
    end
  else
    file = "/etc/yum.repos.d/backup/#{prefix}*.repo"
    execute 'enable all standard yum repos' do
      only_if "ls #{file}"
      command "mv -f #{file} /etc/yum.repos.d/"
    end
  end

  yum_repos = package_repos
  yum_repos.each do |yum_repo|
    Chef::Log.info("Add yum repo #{yum_repo}")
    file = "/etc/yum.repos.d/#{::File.basename(yum_repo)}"
    remote_file file do
      source yum_repo
      mode '0644'
    end
  end

end
