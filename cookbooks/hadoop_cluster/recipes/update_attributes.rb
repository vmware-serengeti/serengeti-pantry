node.default[:hadoop][:install_from_tarball] = is_install_from_tarball
Chef::Log.info("Current distro is " + distro_vendor + " " + distro_version)
Chef::Log.info("Will install the packages using #{node[:hadoop][:install_from_tarball] ? 'tarball' : 'rpm'}")

if is_hadoop_yarn?
  Chef::Log.info('Will deploy a Hadoop YARN cluster because YARN roles are specified.')
else
  Chef::Log.info('Will deploy a Hadoop MRv1 cluster because YARN roles are not specified.')
end

def set_bigtop_hadoop1_attributes
  node.default[:hadoop][:hadoop_conf_dir] = '/etc/hadoop/conf'
  node.default[:hadoop][:hadoop_home_dir] = '/usr/lib/hadoop' # directory that HADOOP is installed in
  node.default[:hadoop][:hadoop_hdfs_dir] = '/usr/lib/hadoop' # directory that HADOOP HDFS is installed in
  node.default[:hadoop][:hadoop_mapred_dir] = '/usr/lib/hadoop-mapreduce'
  # hadoop packages
  node.default[:hadoop][:packages][:hadoop][:name] = "hadoop hadoop-native"
  node.default[:hadoop][:packages][:namenode][:name] = "hadoop-namenode"
  node.default[:hadoop][:packages][:secondarynamenode][:name] = "hadoop-secondarynamenode"
  node.default[:hadoop][:packages][:datanode][:name] = "hadoop-datanode"
  node.default[:hadoop][:packages][:jobtracker][:name] = "hadoop-jobtracker"
  node.default[:hadoop][:packages][:tasktracker][:name] = "hadoop-tasktracker"
  # hadoop system services
  node.default[:hadoop][:namenode_service_name] = "hadoop-namenode"
  node.default[:hadoop][:secondarynamenode_service_name] = "hadoop-secondarynamenode"
  node.default[:hadoop][:datanode_service_name] = "hadoop-datanode"
  node.default[:hadoop][:jobtracker_service_name] = "hadoop-jobtracker"
  node.default[:hadoop][:tasktracker_service_name] = "hadoop-tasktracker"
end

def default_attributes_for_yarn
  node.default[:hadoop][:hadoop_conf_dir] = '/etc/hadoop/conf'
  node.default[:hadoop][:hadoop_home_dir] = '/usr/lib/hadoop' # directory that HADOOP is installed in
  node.default[:hadoop][:hadoop_hdfs_dir] = '/usr/lib/hadoop-hdfs' # directory that HADOOP HDFS is installed in
  node.default[:hadoop][:hadoop_mapred_dir] = '/usr/lib/hadoop-mapreduce' # directory that HADOOP MAPREDUCE is installed in. CDH4 MRv1 and MRv2 has different HADOOP_MAPRED_HOME
  node.default[:hadoop][:yarn_home_dir] = '/usr/lib/hadoop-yarn' # directory that HADOOP YARN is installed in

  # YARN default settings
  node.default[:hadoop][:resource_calculator] = "org.apache.hadoop.yarn.server.resourcemanager.resource.DefaultResourceCalculator"
  node.default[:hadoop][:aux_services] = "mapreduce.shuffle"
end

# Zookeeper Service
node.default[:hadoop][:zookeeper_service_name] = 'zookeeper-server'
node.default[:hadoop][:zookeeper_service_port] = '2181'

if node[:hadoop][:install_from_tarball]
  # For Apache Hadoop 1.0, CDH3, GPHD 1.x, Hortonworks HDP 1.0
  node.default[:hadoop][:packages][:hadoop][:name] = "hadoop"
  node.default[:hadoop][:packages][:namenode][:name] = "hadoop-namenode"
  node.default[:hadoop][:packages][:secondarynamenode][:name] = "hadoop-secondarynamenode"
  node.default[:hadoop][:packages][:datanode][:name] = "hadoop-datanode"
  node.default[:hadoop][:packages][:jobtracker][:name] = "hadoop-jobtracker"
  node.default[:hadoop][:packages][:tasktracker][:name] = "hadoop-tasktracker"
  # hadoop system services
  node.default[:hadoop][:namenode_service_name] = "hadoop-0.20-namenode"
  node.default[:hadoop][:secondarynamenode_service_name] = "hadoop-0.20-secondarynamenode"
  node.default[:hadoop][:datanode_service_name] = "hadoop-0.20-datanode"
  node.default[:hadoop][:jobtracker_service_name] = "hadoop-0.20-jobtracker"
  node.default[:hadoop][:tasktracker_service_name] = "hadoop-0.20-tasktracker"
elsif is_hadoop_yarn?
  default_attributes_for_yarn

  case
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
  if is_hdp2_distro
    node.default[:hadoop][:packages][:journalnode][:name] = "hadoop-hdfs"
  else
    node.default[:hadoop][:packages][:journalnode][:name] = "hadoop-hdfs-journalnode"
  end
  node.default[:hadoop][:packages][:zkfc][:name] = "hadoop-hdfs-zkfc"

  # FIXME package hadoop-hdfs and hadoop-mapreduce are not installed automatically but they contains some common jar files. This is a bug of CDH4.1.2.
  node.default[:hadoop][:packages][:hadoop][:name] = "hadoop hadoop-hdfs hadoop-mapreduce"
  node.default[:hadoop][:packages][:resourcemanager][:name] = "hadoop-yarn-resourcemanager"
  node.default[:hadoop][:packages][:historyserver][:name] = "hadoop-mapreduce-historyserver"
  node.default[:hadoop][:packages][:nodemanager][:name] = "hadoop-yarn-nodemanager"

  # hadoop system services
  node.default[:hadoop][:namenode_service_name] = "hadoop-hdfs-namenode"
  node.default[:hadoop][:secondarynamenode_service_name] = "hadoop-hdfs-secondarynamenode"
  node.default[:hadoop][:datanode_service_name] = "hadoop-hdfs-datanode"
  node.default[:hadoop][:resourcemanager_service_name] = "hadoop-yarn-resourcemanager"
  node.default[:hadoop][:historyserver_service_name] = "hadoop-mapreduce-historyserver"
  node.default[:hadoop][:nodemanager_service_name] = "hadoop-yarn-nodemanager"
elsif is_cdh4_distro
  # For CDH4 MRv1 and bigtop for hadoop2
  node.default[:hadoop][:hadoop_conf_dir] = '/etc/hadoop/conf'
  node.default[:hadoop][:hadoop_home_dir] = '/usr/lib/hadoop' # directory that HADOOP is installed in
  node.default[:hadoop][:hadoop_hdfs_dir] = '/usr/lib/hadoop-hdfs' # directory that HADOOP HDFS is installed in
  node.default[:hadoop][:hadoop_mapred_dir] = '/usr/lib/hadoop-0.20-mapreduce'
  # hadoop packages
  node.default[:hadoop][:packages][:hadoop][:name] = "hadoop hadoop-hdfs hadoop-0.20-mapreduce"
  node.default[:hadoop][:packages][:namenode][:name] = "hadoop-hdfs-namenode"
  node.default[:hadoop][:packages][:secondarynamenode][:name] = "hadoop-hdfs-secondarynamenode"
  node.default[:hadoop][:packages][:datanode][:name] = "hadoop-hdfs-datanode"
  node.default[:hadoop][:packages][:jobtracker][:name] = "hadoop-0.20-mapreduce-jobtracker"
  node.default[:hadoop][:packages][:tasktracker][:name] = "hadoop-0.20-mapreduce-tasktracker"
  node.default[:hadoop][:packages][:journalnode][:name] = "hadoop-hdfs-journalnode"
  node.default[:hadoop][:packages][:zkfc][:name] = "hadoop-hdfs-zkfc"
  # hadoop system services
  node.default[:hadoop][:namenode_service_name] = "hadoop-hdfs-namenode"
  node.default[:hadoop][:secondarynamenode_service_name] = "hadoop-hdfs-secondarynamenode"
  node.default[:hadoop][:datanode_service_name] = "hadoop-hdfs-datanode"
  node.default[:hadoop][:jobtracker_service_name] = "hadoop-0.20-mapreduce-jobtracker"
  node.default[:hadoop][:tasktracker_service_name] = "hadoop-0.20-mapreduce-tasktracker"
elsif is_hdp1_distro or is_bigtop_hadoop1_distro or is_intel_hadoop1_distro
  set_bigtop_hadoop1_attributes
else
  set_bigtop_hadoop1_attributes
end

# hadoop system services
node.default[:hadoop][:namenode_service_port] = is_hadoop_yarn? ? 9000 : 8020
node.default[:hadoop][:jobtracker_service_port] = is_hadoop_yarn? ? 9001 : 8021
node.default[:hadoop][:namenode_web_service_port] = 50070

# hadoop 2.0 hdfs HA services
node.default[:hadoop][:journalnode_service_name] = "hadoop-hdfs-journalnode"
node.default[:hadoop][:journalnode_service_port] = 8485
node.default[:hadoop][:zkfc_service_name] = "hadoop-hdfs-zkfc"
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

# hmonitor ha services
if is_hortonworks_hmonitor_jobtracker_enabled
  node.default[:hadoop][:hmonitor_ha_package] = "jobtracker"
  node.default[:hadoop][:hmonitor_ha_service] = "hmonitor-jobtracker-monitor"
else
  node.default[:hadoop][:hmonitor_ha_package] = "namenode"
  node.default[:hadoop][:hmonitor_ha_service] = "hmonitor-namenode-monitor"
end
