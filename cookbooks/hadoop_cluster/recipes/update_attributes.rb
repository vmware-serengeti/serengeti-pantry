node[:hadoop][:install_from_tarball] = is_install_from_tarball
Chef::Log.info("Will install the packages using #{node[:hadoop][:install_from_tarball] ? 'tarball' : 'rpm'}")

if is_hadoop_yarn?
  Chef::Log.info('Will deploy a Hadoop YARN cluster because YARN roles are specified.')
else
  Chef::Log.info('Will deploy a Hadoop MRv1 cluster because YARN roles are not specified.')
end

if node[:hadoop][:install_from_tarball]
  ## For Apache Hadoop 1.0, CDH3, GPHD 1.x, Hortonworks HDP 1.0
  node.default[:hadoop][:service_name_prefix] = 'hadoop-0.20'
  node.default[:hadoop][:packages][:hadoop][:name] = "hadoop"
  node.default[:hadoop][:packages][:namenode][:name] = "hadoop-namenode"
  node.default[:hadoop][:packages][:secondarynamenode][:name] = "hadoop-secondarynamenode"
  node.default[:hadoop][:packages][:datanode][:name] = "hadoop-datanode"
  node.default[:hadoop][:packages][:jobtracker][:name] = "hadoop-jobtracker"
  node.default[:hadoop][:packages][:tasktracker][:name] = "hadoop-tasktracker"
  node.default[:hadoop][:jobtracker_service_name] = "hadoop-0.20-jobtracker"
  node.default[:hadoop][:tasktracker_service_name] = "hadoop-0.20-tasktracker"
elsif is_hadoop_yarn?
  ## For Hadoop MRv2 (including CDH4 MRv2, Pivotal HD 1.0)
  node.default[:hadoop][:service_name_prefix] = 'hadoop-hdfs'
  node.default[:hadoop][:hadoop_mapred_dir] = '/usr/lib/hadoop-mapreduce' # CDH4 MRv1 and MRv2 has different HADOOP_MAPRED_HOME

  case
  when is_cdh4_distro
    node.default[:hadoop][:hadoop_conf_dir] = '/etc/hadoop/conf'
    node.default[:hadoop][:hadoop_home_dir] = '/usr/lib/hadoop' # directory that HADOOP is installed in
    node.default[:hadoop][:hadoop_hdfs_dir] = '/usr/lib/hadoop-hdfs' # directory that HADOOP HDFS is installed in
    node.default[:hadoop][:hadoop_mapred_dir] = '/usr/lib/hadoop-mapreduce' # directory that HADOOP MAPREDUCE is installed in
    node.default[:hadoop][:yarn_home_dir] = '/usr/lib/hadoop-yarn' # directory that HADOOP YARN is installed in
  when is_pivotalhd_distro
    node.default[:hadoop][:hadoop_conf_dir] = '/etc/gphd/hadoop/conf'
    node.default[:hadoop][:hadoop_home_dir] = '/usr/lib/gphd/hadoop'
    node.default[:hadoop][:hadoop_hdfs_dir] = '/usr/lib/gphd/hadoop-hdfs'
    node.default[:hadoop][:hadoop_mapred_dir] = '/usr/lib/gphd/hadoop-mapreduce'
    node.default[:hadoop][:yarn_home_dir] = '/usr/lib/gphd/hadoop-yarn'
  end

  node.default[:hadoop][:packages][:namenode][:name] = "hadoop-hdfs-namenode"
  node.default[:hadoop][:packages][:secondarynamenode][:name] = "hadoop-hdfs-secondarynamenode"
  node.default[:hadoop][:packages][:datanode][:name] = "hadoop-hdfs-datanode"
  node.default[:hadoop][:packages][:journalnode][:name] = "hadoop-hdfs-journalnode"
  node.default[:hadoop][:packages][:zkfc][:name] = "hadoop-hdfs-zkfc"

  #FIXME package hadoop-hdfs and hadoop-mapreduce are not installed automatically but they contains some common jar files. This is a bug of CDH4.1.2.
  node.default[:hadoop][:packages][:hadoop][:name] = "hadoop hadoop-hdfs hadoop-mapreduce"
  node.default[:hadoop][:packages][:resourcemanager][:name] = "hadoop-yarn-resourcemanager"
  node.default[:hadoop][:packages][:historyserver][:name] = "hadoop-mapreduce-historyserver"
  node.default[:hadoop][:packages][:nodemanager][:name] = "hadoop-yarn-nodemanager"

  node.default[:hadoop][:resourcemanager_service_name] = "hadoop-yarn-resourcemanager"
  node.default[:hadoop][:historyserver_service_name] = "hadoop-mapreduce-historyserver"
  node.default[:hadoop][:nodemanager_service_name] = "hadoop-yarn-nodemanager"
elsif is_cdh4_distro
  ## For CDH4 MRv1
  node.default[:hadoop][:hadoop_mapred_home] = '/usr/lib/hadoop-0.20-mapreduce'
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
end

# hadoop system services
node.default[:hadoop][:namenode_service_name] = "#{node[:hadoop][:service_name_prefix]}-namenode"
node.default[:hadoop][:secondarynamenode_service_name] = "#{node[:hadoop][:service_name_prefix]}-secondarynamenode"
node.default[:hadoop][:datanode_service_name] = "#{node[:hadoop][:service_name_prefix]}-datanode"
node.default[:hadoop][:namenode_service_port] = is_hadoop_yarn? ? 9000 : 8020
node.default[:hadoop][:jobtracker_service_port] = is_hadoop_yarn? ? 9001 : 8021
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
