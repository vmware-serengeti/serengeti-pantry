#
#   Cookbook Name:: zookeeper
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

module Zookeeper

  # whether the node has zookeeper role
  def is_zookeeper
    node.role?("zookeeper")
  end

  def zookeepers_ip
    servers = all_providers_fqdn_for_role("zookeeper")
    Chef::Log.info("Zookeeper servers in cluster #{node[:cluster_name]} are: #{servers.inspect}")
    servers
  end

  def zookeepers_quorum
    servers = zookeepers_ip
    servers.collect { |ip| "#{ip}:#{node[:zookeeper][:client_port]}" }.join(",")
  end

  def wait_for_zookeepers_service(in_ruby_block = true)
    return if is_zookeeper

    run_in_ruby_block __method__, in_ruby_block do
      set_action(HadoopCluster::ACTION_WAIT_FOR_SERVICE, node[:zookeeper][:zookeeper_service_name])
      zookeeper_count = all_nodes_count({"role" => "zookeeper"})
      all_providers_for_service(node[:zookeeper][:zookeeper_service_name], true, zookeeper_count)
      clear_action
    end
  end

end

class Chef::Recipe; include Zookeeper ; end
