node[:hadoop][:install_from_tarball] = is_install_from_tarball
Chef::Log.info("Will install the packages using #{node[:hadoop][:install_from_tarball] ? 'tarball' : 'rpm'}")

if node[:hadoop][:distro_name] =~ /cdh4/ and !node[:hadoop][:install_from_tarball]
  ## For CDH4 MRv1
  node.default[:hadoop][:service_name_prefix] = 'hadoop-hdfs'
  # hadoop packages
  node.default[:hadoop][:packages][:hadoop][:name] = "hadoop"
  node.default[:hadoop][:packages][:namenode][:name] = "hadoop-hdfs-namenode"
  node.default[:hadoop][:packages][:secondarynamenode][:name] = "hadoop-hdfs-secondarynamenode"
  node.default[:hadoop][:packages][:datanode][:name] = "hadoop-hdfs-datanode"
  node.default[:hadoop][:packages][:jobtracker][:name] = "hadoop-0.20-mapreduce-jobtracker"
  node.default[:hadoop][:packages][:tasktracker][:name] = "hadoop-0.20-mapreduce-tasktracker"
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
