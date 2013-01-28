node[:hadoop][:install_from_tarball] = is_install_from_tarball
Chef::Log.info("Will install the packages using #{node[:hadoop][:install_from_tarball] ? 'tarball' : 'rpm'}")

if is_cdh4_distro and !node[:hadoop][:install_from_tarball]
  ## For CDH4 MRv1
  node.default[:hadoop][:service_name_prefix] = 'hadoop-hdfs'
  # hadoop packages
  node.default[:hadoop][:packages][:hadoop][:name] = "hadoop"
  node.default[:hadoop][:packages][:namenode][:name] = "hadoop-hdfs-namenode"
  node.default[:hadoop][:packages][:secondarynamenode][:name] = "hadoop-hdfs-secondarynamenode"
  node.default[:hadoop][:packages][:datanode][:name] = "hadoop-hdfs-datanode"
  node.default[:hadoop][:packages][:jobtracker][:name] = "hadoop-0.20-mapreduce-jobtracker"
  node.default[:hadoop][:packages][:tasktracker][:name] = "hadoop-0.20-mapreduce-tasktracker"
  node.default[:hadoop][:packages][:journalnode][:name] = "hadoop-hdfs-journalnode"
  node.default[:hadoop][:packages][:zkfc][:name] = "hadoop-hdfs-zkfc"
  # hadoop system services
  node.default[:hadoop][:jobtracker_service_name] = "hadoop-0.20-mapreduce-jobtracker"
  node.default[:hadoop][:tasktracker_service_name] = "hadoop-0.20-mapreduce-tasktracker"
else
  node.default[:hadoop][:service_name_prefix] = 'hadoop-0.20'
  node.default[:hadoop][:packages][:hadoop][:name] = "hadoop"
  node.default[:hadoop][:packages][:namenode][:name] = "hadoop-namenode"
  node.default[:hadoop][:packages][:secondarynamenode][:name] = "hadoop-secondarynamenode"
  node.default[:hadoop][:packages][:datanode][:name] = "hadoop-datanode"
  node.default[:hadoop][:packages][:jobtracker][:name] = "hadoop-jobtracker"
  node.default[:hadoop][:packages][:tasktracker][:name] = "hadoop-tasktracker"
  node.default[:hadoop][:jobtracker_service_name] = "hadoop-0.20-jobtracker"
  node.default[:hadoop][:tasktracker_service_name] = "hadoop-0.20-tasktracker"
end

# hadoop system services
node.default[:hadoop][:namenode_service_name] = "#{node[:hadoop][:service_name_prefix]}-namenode"
node.default[:hadoop][:secondarynamenode_service_name] = "#{node[:hadoop][:service_name_prefix]}-secondarynamenode"
node.default[:hadoop][:datanode_service_name] = "#{node[:hadoop][:service_name_prefix]}-datanode"
node.default[:hadoop][:namenode_service_port] = node[:hadoop][:is_hadoop_yarn] ? 9000 : 8020
node.default[:hadoop][:jobtracker_service_port] = node[:hadoop][:is_hadoop_yarn] ? 9001 : 8021
node.default[:hadoop][:namenode_web_service_port] = 50070

# hadoop 2.0 hdfs HA services
node.default[:hadoop][:journalnode_service_name] = "hadoop-hdfs-journalnode"
node.default[:hadoop][:journalnode_service_port] = 8485
node.default[:hadoop][:zkfc_service_name] = "hadoop-hdfs-zkfc"
node.default[:hadoop][:zookeeper_service_name] = 'zookeeper-server'
node.default[:hadoop][:zookeeper_service_port] = '2181'
node.default[:hadoop][:primary_namenode_format] = 'primary-namenode-format'
node.default[:hadoop][:standby_namenode_format] = 'standby-namenode-format'
node.default[:hadoop][:primary_zkfc_format] = 'primary-zkfc-format'

# Save attribute cluster_has_hdfs_ha_or_federation to chef server if cluster has HDFS HA or federation
if cluster_has_hdfs_ha_or_federation
  node.default[:hadoop][:cluster_has_hdfs_ha_or_federation] = true
end

# Save attribute cluster_has_only_federation to chef server if cluster has only federation
if cluster_has_only_federation
  node.default[:hadoop][:cluster_has_only_federation] = true
end

# Save attribute namenode_ha_enabled to chef server if namenode ha is enabled
if namenode_ha_enabled
  node.default[:hadoop][:namenode_ha_enabled] = true
end
