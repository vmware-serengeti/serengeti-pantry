#
# Author:: Philip (flip) Kromer for Infochimps.org
# Cookbook Name:: cassandra
# Recipe:: autoconf
#
# Copyright 2010, Infochimps, Inc
# Portions Copyright (c) 2012-2013 VMware, Inc. All rights Reserved.
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

# Much inspiration for this code taken from corresponding functionality in
# Benjamin Black (<b@b3k.us>)'s cassandra cookbooks
#

#
# ClusterServiceDiscovery --
#
# Allow nodes to discover the location for a given service at runtime, adapting
# when new services register.
#
# Operations:
#
# * provide a service. A timestamp records the last registry.
# * discover all providers for the given service.
# * discover the most recent provider for that service.
# * get the 'public_ip' for a provider -- the address that nodes in the larger
#   world should use
# * get the 'public_ip' for a provider -- the address that nodes on the local
#   subnet / private cloud should use
#
# Implementation
#
# Nodes register a service by setting the +[:provides_service][service_name]+
# attribute. This attribute is a hash containing at 'timestamp' (the time of
# registry), but the service can pass in an arbitrary hash of values to merge
# in.
#
module ClusterServiceDiscovery
  WAIT_TIMEOUT = 1800 # seconds
  SLEEP_TIME = 5
  ABORT_DETECT_INTERVAL = 2 # detect abort signal every 2 * SLEEP_TIME seconds

  # Find all nodes that have indicated they provide the given service,
  # in descending order of when they registered.
  #
  def all_providers_for_service service_name, wait = true, num = 1, monitor = true
    set_action(HadoopCluster::ACTION_WAIT_FOR_SERVICE, service_name) if monitor
    condition = "cluster_name:#{node[:cluster_name]} AND provides_service:#{service_name}"
    nodes = all_providers(service_name, condition, wait, num, false) do
      search(:node, "#{condition}").
        find_all{|server| server[:provides_service][service_name] && server[:provides_service][service_name]['timestamp'] }.
        sort_by{|server| server[:provides_service][service_name]['timestamp'] } rescue []
    end
    clear_action if monitor
    nodes
  end

  # Find all nodes that have indicated they provide the given role.
  # The param num means at least find #{num} nodes.
  def all_providers_for_role role_name, wait = true, num = 1
    condition = "cluster_name:#{node[:cluster_name]} AND role:#{role_name}"
    all_providers(role_name, condition, wait, num, false) do
      search(:node, "#{condition}").
        sort_by{ |server| server[:facet_index] } rescue []
    end
  end

  def all_providers name, condition = "", wait = true, num = 1, run_in_ruby_block = true, &block
    if run_in_ruby_block
      ruby_block "find-provider-for-#{name}" do
        block do
          get_all_providers(name, condition, wait, num, run_in_ruby_block, &block)
        end
      end
    else
      get_all_providers(name, condition, wait, num, run_in_ruby_block, &block)
    end
  end

  # Find all nodes that have indicated they provide the given type.
  # The param num means at least find #{num} nodes.
  def get_all_providers name, condition, wait, num, run_in_ruby_block, &block
    start_time = Time.now
    count = 0
    while true
      servers = yield
      if !wait or (servers and servers.size >= num)
        Chef::Log.info("search(:node, '#{condition}') returns #{servers.count} nodes.")
        return servers
      else
        wait_time = Time.now - start_time
        if wait_time > WAIT_TIMEOUT
          Chef::Log.error("search(:node, '#{condition}') failed, return empty.")
          raise "Can't find any nodes which provide #{name}. Did any node provide #{name}? Or is the Chef Solr Server down?"
        end
        Chef::Log.info("search(:node, '#{condition}') returns nothing, already wait #{wait_time} seconds.")
        sleep SLEEP_TIME

        count += 1
        check_abort_signal if (count % ABORT_DETECT_INTERVAL) == 0
      end
    end
  end

  # Find the most recent node that registered to provide the given service
  def provider_for_service service_name, wait = true
    all_providers_for_service(service_name, wait).last
  end

  # Find the most recent node that registered to provide the given role
  def provider_for_role role_name, wait = true
    all_providers_for_role(role_name, wait).last
  end

  # Notify
  def notify notify_name, notify_info = {}
    provide_service(notify_name, notify_info)
  end

  # Wait until some nodes match the given condition. This will run in a ruby block by default.
  def wait_for name, conditions = {}, wait = true, num = 1, run_in_ruby_block = true
    providers_for(name, conditions, wait, num, run_in_ruby_block)
  end

  # Wait for the service to be started.
  # The service provider might be one or more. The param num means wait for at least #{num} providers.
  # This will not run in a ruby block by default.
  def wait_for_service(service_name, num = 1, run_in_ruby_block = false)
    set_action(HadoopCluster::ACTION_WAIT_FOR_SERVICE, service_name)
    condition = "cluster_name:#{node[:cluster_name]} AND provides_service:#{service_name}"
    all_providers(service_name, condition, true, num, run_in_ruby_block) do
      # Use Chef Partial Search to speed up the query, since we don't need the node object here.
      # See doc http://docs.opscode.com/essentials_search.html#partial-search
      partial_search(:node, "#{condition}", :keys => { 'name' => ['name'] })
    end
    clear_action
  end

  # Get the nodes which match the given condition. This will not run in a ruby block by default.
  def providers_for name, conditions = {}, wait = true, num = 1, run_in_ruby_block = false
    condition = generate_condition(conditions)
    all_providers(name, condition, wait, num, run_in_ruby_block) do
      search(:node, "#{condition}").sort_by{ |server| server[:facet_index] } rescue []
    end
  end

  # Return the node which matches the given condition.
  def provider_for name, conditions = {}, wait = true
    providers_for(name, conditions, wait).last
  end

  # Register to provide the given service.
  # If you pass in a hash of information, it will be added to the registry, and available to clients
  def run_provide_service service_name, service_info = {}, wait = false
    Chef::Log.info("Registering to provide service '#{service_name}' with extra info: #{service_info.inspect}")
    timestamp = ClusterServiceDiscovery.timestamp
    node.set[:provides_service][service_name] = {
      :timestamp  => timestamp
    }.merge(service_info)
    node.save

    # Typically when bootstrap the chef node for the first time, the chef node registers itself to provide some service,
    # but the Chef Search Server is not faster enough to build index for newly added node property(e.g. 'provides_service'),
    # and will return stale results for search(:node, "provides_service:#{service_name}").
    # So let's wait for Chef Search Server to generate the search index.
    # However in large scale cluster, Chef Search API is very time consuming(comparing to Chef Get/Delete/Update API),
    # we need to reduce Chef Search API calls to Chef Server. Since provider_for_service() will by default wait for
    # Chef Solr to generate the index, so we don't need to wait here by default.
    if wait
      found = false
      while !found do
        Chef::Log.info("Wait for Chef Solr Server to generate search index for property 'provides_service'")
        sleep SLEEP_TIME
        # a service can be provided by multi nodes, e.g. zookeeper server service
        servers = all_providers_for_service(service_name, true, 1, false)
        servers.each do |server|
          if server[:ipaddress] == node[:ipaddress] and server[:provides_service][service_name][:timestamp] == timestamp
            found = true
            break
          end
        end
      end
    end
    Chef::Log.info("service '#{service_name}' is registered successfully.")
  end

  # return facet name of the node
  def facet_name_of_server server
    server[:facet_name] rescue nil
  end

  def provide_service service_name, service_info = {}, run_in_ruby_block = true
    if run_in_ruby_block
      ruby_block "provide-#{service_name}" do
        block do
          run_provide_service(service_name, service_info)
        end
      end
    else
      run_provide_service(service_name, service_info)
    end
  end

  # given service, get most recent address

  # The local-only ip address for the most recent provider for service_name
  def provider_private_ip service_name, wait = true
    server = provider_for_service(service_name, wait) or return
    private_ip_of(server)
  end

  # The local-only ip address for the most recent provider for service_name
  def provider_fqdn service_name, wait = true
    server = provider_for_service(service_name, wait) or return
    fqdn_of_service(server, service_name)
  end

  # The local-only ip address for the most recent provider for role_name
  def provider_fqdn_for_role role_name, wait = true
    server = provider_for_role(role_name, wait) or return
    fqdn_of_server(server, role_name)
  end

  def provider_ip_for_role role_name, wait = true
    server = provider_for_role(role_name, wait) or return
    ip_of(server)
  end

  # The globally-accessable ip address for the most recent provider for service_name
  def provider_public_ip service_name, wait = true
    server = provider_for_service(service_name, wait) or return
    public_ip_of(server)
  end

  # given service, get many addresses

  # The local-only ip address for all providers for service_name
  def all_provider_private_ips service_name, wait = true, num = 1
    servers = all_providers_for_service(service_name, wait, num)
    servers.map{ |server| private_ip_of(server) }
  end

  # The globally-accessable ip address for all providers for service_name
  def all_provider_public_ips service_name, wait = true, num = 1
    servers = all_providers_for_service(service_name, wait, num)
    servers.map{ |server| public_ip_of(server) }
  end

  # The local-only ip address for all providers for role_name
  def all_provider_private_ips_for_role role_name
    servers = all_providers_for_role(role_name)
    servers.map{ |server| private_ip_of(server) }
  end

  # The globally-accessable ip address for all providers for role_name
  def all_provider_public_ips_for_role role_name
    servers = all_providers_for_role(role_name)
    servers.map{ |server| ip_of(server) }
  end

  def all_providers_fqdn_for_role role_name
    servers = all_providers_for_role(role_name)
    servers.map{ |server| fqdn_of_server(server, role_name)}
  end

  # given server, get address

  # The local-only ip address for the given server
  def private_ip_of server
    server[:cloud][:private_ips].first rescue server[:ipaddress]
  end

  # The local-only ip address for the given server
  def fqdn_of_service server, service_name = nil
    # if cannot fetch fqdn, return the mgt ip's fqdn
    begin
      return server[:provides_service][service_name][:fqdn]
    rescue
      return fqdn_of_mgt_network(server)
    end
  end

  # The globally-accessable ip address for the given server
  def public_ip_of server
    server[:cloud][:public_ips].first  rescue server[:ipaddress]
  end

  # The ip address for the given server & traffic_type
  def ip_of server
    ip_of_mgt_network(server)
  end

  # All nodes count have given conditions
  def all_nodes_count conditions = {}
    all_nodes(conditions).count
  end

  # All nodes have given conditions
  def all_nodes conditions = {}
    condition = generate_condition(conditions)
    search(:node, "#{condition}") rescue []
  end

  # Generate search node condition
  def generate_condition conditions
    condition = "cluster_name:#{node[:cluster_name]}"
    conditions.each do |key, value|
      condition += " AND #{key}:#{value}"
    end
    condition
  end

  def check_abort_signal
    Chef::Log.debug("Checking whether abort signal is set to true by Ironfan")
    item = data_bag_item(node[:cluster_name], node[:cluster_name]) rescue item = {}
    Chef::Log.debug("abort signal is #{item['abort']}")
    if item['abort']
      raise "The abort signal is detected. Some key nodes failed to bootstrap, so abort bootstrapping node #{node.name}."
    end
  end

  # A compact timestamp, to record when services are registered
  def self.timestamp
    Time.now.utc.strftime("%Y%m%d%H%M%SZ")
  end

end
class Chef::Recipe              ; include ClusterServiceDiscovery ; end
class Chef::Resource::Directory ; include ClusterServiceDiscovery ; end
class Chef::Resource            ; include ClusterServiceDiscovery ; end
