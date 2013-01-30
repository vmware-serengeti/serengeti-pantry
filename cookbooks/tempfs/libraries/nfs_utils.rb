#
#   Portions Copyright (c) 2012 VMware, Inc. All Rights Reserved.
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
module NFS
  def  ref_servers_num role
    condition = "cluster_name:#{node[:cluster_name]} AND role:#{role}"
    nodes = search(:node, "#{condition}")
    servers_on_all_hosts = nodes.size
    servers_on_this_host = nodes.select{ |n| n[:provision][:physical_host] == node[:provision][:physical_host] }.size
    {:all_hosts => servers_on_all_hosts, :this_host => servers_on_this_host}
  end

  def full_name server
    "#{server[:cluster_name]}-#{server[:facet_name]}-#{server[:facet_index]}"
  end
end

class Chef::Recipe
  include NFS
end
