default[:hbase][:home_dir] = '/usr/lib/hbase'
default[:hbase][:conf_dir] = '/usr/lib/hbase/conf'
default[:hbase][:version]  = "0.94.0"

default[:hbase][:hdfshome] = '/hadoop/hbase'
default[:hbase][:master_service_name] = 'hbase-master'
default[:hbase][:region_service_name] = 'hbase-regionserver'
default[:hbase][:zookeeper_service_name] = "zookeeper-server"
default[:hbase][:rest_service_name] = 'hbase-rest'
default[:hbase][:thrift_service_name] = 'hbase-thrift'

default[:hbase][:zookeeper_session_timeout] = "180000" # milliseconds
default[:hbase][:package_name] = "hbase"
