#
#   Copyright (c) 2012-2013 VMware, Inc. All Rights Reserved.
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

if node[:hadoop][:install_from_tarball]
  template '/etc/init.d/hive-server' do
    source 'hive-server.erb'
    owner 'root'
    group 'root'
    mode '0755'
  end
else
  package 'hive-server'
end

service "hive-server" do
  supports :status => true, :restart => true, :reload => true
  action [:enable, :start]
  subscribes :restart, resources("file[#{node[:hive][:home_dir]}/conf/hive-site.xml]"), :delayed
end
