default[:hbase][:home_dir]           = '/usr/lib/hbase'
default[:hbase][:version]            = "0.94.0"

default[:hbase][:hdfshome] = '/hadoop/hbase'
default[:hbase][:master_service_name] = 'hbase-master'
default[:hbase][:master_service_registry_name] = "#{node[:cluster_name]}-hbase-master"
default[:hbase][:region_service_name] = 'hbase-regionserver'
default[:hbase][:zookeeper_service_name] = "#{node[:cluster_name]}-zookeeper-server"
