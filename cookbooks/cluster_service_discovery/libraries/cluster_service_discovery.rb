#
# Author:: Philip (flip) Kromer for Infochimps.org
# Cookbook Name:: cassandra
# Recipe:: autoconf
#
# Copyright 2010, Infochimps, Inc
# Portions Copyright (c) 2012 VMware, Inc. All rights Reserved.
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
  WAIT_TIMEOUT = 600 # seconds
  SLEEP_TIME = 5

  # Find all nodes that have indicated they provide the given service,
  # in descending order of when they registered.
  #
  def all_providers_for_service service_name, wait = true
    start_time = Time.now
    while true
      servers = search(:node, "provides_service:#{service_name}").
        find_all{|server| server[:provides_service][service_name] && server[:provides_service][service_name]['timestamp'] }.
        sort_by{|server| server[:provides_service][service_name]['timestamp'] } rescue []
      if !wait or (servers and servers.size > 0)
        Chef::Log.info("search(:node, 'provides_service:#{service_name}') returns #{servers.count} nodes.")
        return servers
      else
        wait_time = Time.now - start_time
        if wait_time > WAIT_TIMEOUT
          Chef::Log.error("search(:node, 'provides_service:#{service_name}') failed, return empty.")
          raise "Can't find any nodes which provide service #{service_name}. Did any node register this service? Or is the Chef Search Server is down?"
        end
        Chef::Log.info("search(:node, 'provides_service:#{service_name}') returns nothing, already wait #{wait_time} seconds.")
        sleep SLEEP_TIME
      end
    end
  end

  # Find the most recent node that registered to provide the given service
  def provider_for_service service_name, wait = true
    all_providers_for_service(service_name, wait).last
  end

  # Register to provide the given service.
  # If you pass in a hash of information, it will be added to the registry, and available to clients
  def provide_service service_name, service_info = {}
    Chef::Log.info("Registering to provide service '#{service_name}' with extra info: #{service_info.inspect}")
    timestamp = ClusterServiceDiscovery.timestamp
    node.set[:provides_service][service_name] = {
      :timestamp  => timestamp,
    }.merge(service_info)
    node.save

    # Typically when bootstrap the chef node for the first time, the chef node registers itself to provide some service,
    # but the Chef Search Server is not faster enough to build index for newly added node property(e.g. 'provides_service'),
    # and will return stale results for search(:node, "provides_service:#{service_name}").
    # So let's wait for Chef Search Server to generate the search index.
    found = false
    while !found do
      Chef::Log.info("Wait for Chef Solr Server to generate search index for property 'provides_service'")
      sleep SLEEP_TIME
      # a service can be provided by multi nodes, e.g. zookeeper server service
      servers = all_providers_for_service(service_name)
      servers.each do |server|
        if server[:ipaddress] == node[:ipaddress] and server[:provides_service][service_name][:timestamp] == timestamp
          found = true
          break
        end
      end
    end
    Chef::Log.info("service '#{service_name}' is registered successfully.")
  end

  # given service, get most recent address

  # The local-only ip address for the most recent provider for service_name
  def provider_private_ip service_name, wait = true
    server = provider_for_service(service_name, wait) or return
    private_ip_of(server)
  end

  # The local-only ip address for the most recent provider for service_name
  def provider_fqdn service_name
    server = provider_for_service(service_name) or return
    # Chef::Log.info("for #{service_name} got #{server.inspect} with #{fqdn_of(server)}")
    fqdn_of(server)
  end

  # The globally-accessable ip address for the most recent provider for service_name
  def provider_public_ip service_name
    server = provider_for_service(service_name) or return
    public_ip_of(server)
  end

  # given service, get many addresses

  # The local-only ip address for all providers for service_name
  def all_provider_private_ips service_name
    servers = all_providers_for_service(service_name)
    servers.map{ |server| private_ip_of(server) }
  end

  # The globally-accessable ip address for all providers for service_name
  def all_provider_public_ips service_name
    servers = all_providers_for_service(service_name)
    servers.map{ |server| public_ip_of(server) }
  end

  # given server, get address

  # The local-only ip address for the given server
  def private_ip_of server
    server[:cloud][:private_ips].first rescue server[:ipaddress]
  end

  # The local-only ip address for the given server
  def fqdn_of server
    server[:fqdn]
  end

  # The globally-accessable ip address for the given server
  def public_ip_of server
    server[:cloud][:public_ips].first  rescue server[:ipaddress]
  end

  # A compact timestamp, to record when services are registered
  def self.timestamp
    Time.now.utc.strftime("%Y%m%d%H%M%SZ")
  end

end
class Chef::Recipe              ; include ClusterServiceDiscovery ; end
class Chef::Resource::Directory ; include ClusterServiceDiscovery ; end
class Chef::Resource            ; include ClusterServiceDiscovery ; end
