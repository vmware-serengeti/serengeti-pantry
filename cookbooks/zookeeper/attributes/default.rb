default[:zookeeper][:home_dir]           = '/usr/lib/zookeeper'
default[:zookeeper][:version]            = "3.4.3"

# ZK defaults
default[:zookeeper][:tick_time] = 2000
default[:zookeeper][:init_limit] = 10
default[:zookeeper][:sync_limit] = 5
default[:zookeeper][:client_port] = 2181
default[:zookeeper][:peer_port] = 2888
default[:zookeeper][:leader_port] = 3888

default[:zookeeper][:zookeeper_service_name] = 'zookeeper-server'
