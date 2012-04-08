default[:hbase][:hbase_package_name] = 'hbase'
default[:hbase][:hbase_package_version] = nil
default[:hbase][:hbase_home] = '/usr/lib/hbase'
default[:hbase][:master_service_name] = 'hbase-master'
default[:hbase][:region_service_name] = 'hbase-regionserver'

default[:hbase][:hbase_hdfshome] = '/hadoop/hbase'

default[:hbase][:master_service_registry_name] = "#{node[:cluster_name]}-hbase-masterserver"

default[:hbase][:zookeeper_service_registry_name] = "#{node[:cluster_name]}-zookeeper" # Zookeeper service to be used by HBase
