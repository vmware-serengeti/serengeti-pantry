default[:zookeeper][:cluster_name] = node[:cluster_name] # the name of zookeeper cluster
default[:zookeeper][:cluster_servers_count] = 3 # the zookeeper servers count in the zookeeper cluster; at least 3.
default[:zookeeper][:service_registry_name] = "#{node[:zookeeper][:cluster_name]}-zookeeper" # service name to be registed in cluster_service_discovery

default[:users ]['zookeeper'][:uid] = 310
default[:groups]['zookeeper'][:gid] = 310
default[:zookeeper][:data_dir] = '/var/lib/zookeeper'
default[:zookeeper][:log_dir] = '/var/log/zookeeper'
default[:zookeeper][:max_client_connections] = 30

default[:zookeeper][:zookeeper_server_package_name] = 'zookeeper-server' # apply to CDH4b1
default[:zookeeper][:zookeeper_package_name] = 'zookeeper'
default[:zookeeper][:zookeeper_service_name] = 'zookeeper-server'


