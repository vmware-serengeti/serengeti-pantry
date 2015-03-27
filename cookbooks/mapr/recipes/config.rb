#
#   Portions Copyright (c) 2012-2014 VMware, Inc. All Rights Reserved.
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

# Config MapR
client = node.role?('mapr_client') ? "-c" : ""
config_command = "/opt/mapr/server/configure.sh #{client}" +
  " -N #{node[:cluster_name]} -C " + cldbs_address + " -Z " + zookeepers_address

rm = resourcemanagers_address
hs = historyserver_address
if !rm.empty?
  config_command += " -RM #{rm} -HS #{hs}"
end

execute "config MapR" do
  user "root"
  command config_command
end

# Config disks
include_recipe 'mapr::config_disks'

# Config metrics
include_recipe 'mapr::config_metrics'

# Config compute-only node
include_recipe 'mapr::compute_only'

# Config Hadoop
include_recipe 'mapr::config_hadoop'