#
# Cookbook Name:: hbase
# Recipe:: regionserver
#
# Copyright 2012, VMware Inc.
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

# Install HBase Region Server
package "#{node[:hbase][:hbase_package_name]}-regionserver" do
  if node[:hbase][:hbase_package_version]
    version node[:hbase][:hbase_package_version]
  end
end

# Conf files
include_recipe 'hbase::conf'

# Launch service
service node[:hbase][:region_service_name] do
  action [ :enable, :restart ]
  running true
  supports :status => true, :restart => true
end
