#
# Cookbook Name:: nfs
# Recipe::        client
#

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

include_recipe "tempfs::default"

SERVICE_WAIT_TIME_SEC = 1800
start_time = Time.now.to_i
expect_servers_num = (ref_servers_num("tempfs_server") + 1) / 2
while (Time.now.to_i - start_time < SERVICE_WAIT_TIME_SEC)
  my_servers = []
  all_servers = all_providers_for_service node[:nfs][:nfs_service_name]
  all_servers.each { |server|
    if server[:provision][:physical_host] == node[:provision][:physical_host] and server[:cluster_name] == node[:cluster_name]
      my_servers << server
    end
  }

  # try to avoid attaching all compute nodes to one data nodes
  sleep(3) and next if my_servers.size < expect_servers_num
  server_selected = my_servers[node[:ipaddress].hash % my_servers.size]

  map_dirs = []
  export_dirs = server_selected[:provides_service][node[:nfs][:nfs_service_name]][:export_dirs]
  nfs_server_ip = server_selected[:ipaddress]
  mount_count = 0

  export_dirs.each do |remote_dir|
    begin
      mount_dir = "/mnt/mapred#{mount_count}"
      # Remove dir
      directory mount_dir do
        action :delete
        recursive true
      end

      # Create Dir
      directory mount_dir do
        owner "mapred"
        group "hadoop"
        mode  '0755'
        action :create
        recursive true
      end
      mount_count += 1

      Chef::Log.info("Processing mount of #{mount_dir} from #{nfs_server_ip} (#{remote_dir})")
      mount mount_dir do
        fstype      "nfs"
        options     "rw,nointr,rsize=131072,wsize=131072,tcp"
        device      "#{nfs_server_ip}:#{remote_dir}"
        dump        0
        pass        0
        action      :mount
      end
      mount_map_dir = "#{mount_dir}/#{node[:ipaddress]}"
      directory mount_map_dir do
        owner "mapred"
        group "hadoop"
        mode  '0755'
        action :create
      end
      map_dirs << mount_map_dir
    rescue StandardError => err
      Chef::Log.warn "Problem setting up NFS:"
      Chef::Log.warn err
    end
  end
  node[:nfs_mapred_dirs] = map_dirs
  node.save
  break
end
