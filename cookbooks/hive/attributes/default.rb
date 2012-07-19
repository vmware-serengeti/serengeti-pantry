default[:hadoop][:packages][:hive][:name] = "hadoop-hive"

default[:hive][:home_dir]           = '/usr/lib/hive'
default[:hive][:version]            = "0.8.1"
default[:hive][:log_dir]            = "/var/log/hive"
default[:hive][:pid_dir]            = "/var/run/hive"
default[:hive][:user]               = "hive"
default[:hive][:group]              = "hive"
default[:groups][:hive][:gid]       = 503
default[:hive][:metastore_db]       = "metastore_db"
default[:hive][:metastore_user]     = "hive"

default[:groups][:hive][:gid]       = 503

default[:postgresql][:dir]          = "/var/lib/pgsql/data"
