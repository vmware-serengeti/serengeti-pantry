#
#   Cookbook Name:: hadoop_common
#   Recipe Name  :: pre_run
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

# Set Chef Logger format
Chef::Log.formatter = proc do |severity, datetime, progname, msg|
  "[#{datetime.strftime('%Y-%m-%dT%H:%M:%S.%L%z')}] #{severity}: #{msg}\n"
end

Chef::Log.info("Chef Server is " + Chef::Config[:chef_server_url])

# add chef error reporting handler
include_recipe 'hadoop_common::add_chef_handler'

wait_for_fqdn_ddns_registration()

### When there are multi NICs on the node ###

# update IP attributes
update_ipconfigs()

# set node[:fqdn] to FQDN of the network which Chef Workstation is in.
fqdn = fqdn_of_mgt_network(node)
if node[:fqdn] != fqdn
  node.set[:fqdn] = fqdn
  node.save
end

# VHM get TaskTracker's name by fetch hostname from VC for decommission,
# so we need to make sure hostname is consistent with the one TaskTracker
# using. For JobTracker/ResourceManager, set to mgt_fqdn since VHM need
# to ssh login to it.
if node.role?("hadoop_tasktracker") or node.role?("hadoop_nodemanager")
  fqdn = fqdn_of_mapred_network(node)
end
set_hostname(fqdn)

### End of multi NICs ###

