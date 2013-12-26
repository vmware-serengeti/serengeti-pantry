default[:hive][:home_dir]           = '/usr/lib/hive'
default[:hive][:version]            = "0.8.1"
default[:hive][:log_dir]            = "/var/log/hive"
default[:hive][:pid_dir]            = "/var/run/hive"
default[:hive][:conf_dir]           = "/usr/lib/hive/conf"
default[:hive][:user]               = "hive"
default[:hive][:group]              = "hive"
default[:groups][:hive][:gid]       = 503
default[:hive][:metastore_db]       = "metastore_db"
default[:hive][:metastore_user]     = "hive"
default[:groups][:hive][:gid]       = 503

default[:hadoop][:packages][:hive][:name] = "hive"
default[:hadoop][:packages][:hive_server][:name] = "hive-server"
default[:hadoop][:hive_service_name] = 'hive-server'
