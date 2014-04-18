#
# Cookbook Name:: nfs
# Recipe::        client
#

#
#   Portions Copyright (c) 2012-2014 VMware, Inc. All Rights Reserved.
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

include_recipe "tempfs::default"

SERVICE_WAIT_TIME_SEC = 1800
start_time = Time.now.to_i
servers_num =  ref_servers_num("tempfs_server")
while (Time.now.to_i - start_time < SERVICE_WAIT_TIME_SEC)
  server_selected = nil
  retrieved_servers = all_providers_for_service(node[:nfs][:nfs_service_name]).select{ |n| n[:cluster_name] == node[:cluster_name]}
  candidate_servers = retrieved_servers
  if !node[:selected_nfs_server].nil?
    retrieved_servers.each do |server|
      if full_name(server) == node[:selected_nfs_server]
        server_selected = server
        break
      end
    end
    sleep(3) and next if retrieved_servers.size < servers_num[:all_hosts] && server_selected.nil?
  else # this recipe has never been ran before or the data server this compute node attached is missed
    if servers_num[:this_host] > 0
      candidate_servers = retrieved_servers.select{ |n| n[:provision][:physical_host] == node[:provision][:physical_host]}
      sleep(3) and next if candidate_servers.size < ( servers_num[:this_host] + 1 ) / 2
    else
      sleep(3) and next if candidate_servers.size < ( servers_num[:all_hosts] + 1 ) / 2
    end
  end

  if server_selected.nil?
    # avoid attaching all compute nodes to one data nodes
    server_selected = candidate_servers[node[:ipaddress].hash % candidate_servers.size]
  end

  export_entries = server_selected[:provides_service][node[:nfs][:nfs_service_name]][:export_entries]
  map_dirs = []
  nfs_server_ip = server_selected[:ipaddress]

  begin
    mount_dir = "/mnt/mapred"

    # Create Dir
    directory mount_dir do
      owner "mapred"
      group "hadoop"
      mode  '0755'
      action :create
      recursive true
    end

    service "start-rpcidmapd" do
      service_name "rpcidmapd"
      action [ :enable, :start ]
      supports :status => true, :restart => true
    end

    Chef::Log.info("Processing mount of #{mount_dir} from #{nfs_server_ip}:/")
    mount mount_dir do
      not_if      "grep '#{nfs_server_ip}' /etc/mtab > /dev/null"
      fstype      "nfs4"
      options     "rw,nointr,rsize=131072,wsize=131072"
      device      "#{nfs_server_ip}:/"
      dump        0
      pass        0
      action      :mount
    end

    export_entries.each do |entry|
      mount_map_dir = "#{mount_dir}/#{entry}/#{node[:cluster_name]}-#{node[:facet_name]}-#{node[:facet_index]}"
      directory mount_map_dir do
        owner "mapred"
        group "hadoop"
        mode  '0755'
        action :create
      end
      map_dirs << mount_map_dir
    end
  rescue StandardError => err
    Chef::Log.warn "Problem setting up NFS:"
    Chef::Log.warn err
  end
  node[:nfs_mapred_dirs] = map_dirs
  node[:selected_nfs_server] = full_name(server_selected)
  node.save
  break
end
