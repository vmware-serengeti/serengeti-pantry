#
# Cookbook Name:: hadoop_cluster
# Recipe::        cluster_conf
#
class Chef::Recipe; include HadoopCluster ; end

# Hadoop xml configuration files in $HADDOP_HOME/conf/
include_recipe "hadoop_cluster::hadoop_conf_xml"

# Add symlinks to HADOOP_HOME
force_link("/usr/lib/hadoop", "/usr/lib/#{node[:hadoop][:hadoop_handle]}")

# Make hadoop logs live on /mnt/hadoop
hadoop_log_dir = local_hadoop_log_dir
make_hadoop_dir(hadoop_log_dir, 'hdfs', "0775")
force_link("/var/log/hadoop", hadoop_log_dir )
force_link("/var/log/#{node[:hadoop][:hadoop_handle]}", hadoop_log_dir )

# Make hadoop point to /var/run for pids
make_hadoop_dir("/var/run/#{node[:hadoop][:hadoop_handle]}", 'root', "0775")
force_link('/var/run/hadoop', "/var/run/#{node[:hadoop][:hadoop_handle]}")

# Fix the hadoop-env.sh to point to /var/run for pids
hadoop_env_file = "/etc/hadoop/conf/hadoop-env.sh"
execute 'fix_hadoop_env-pid' do
  command %Q{sed -i -e 's|# export HADOOP_PID_DIR=.*|export HADOOP_PID_DIR=/var/run/hadoop|' #{hadoop_env_file}}
  not_if "grep 'HADOOP_PID_DIR=/var/run/hadoop' #{hadoop_env_file}"
end

# Set SSH options within the cluster
execute 'fix_hadoop_env-ssh' do
  command %Q{sed -i -e 's|# export HADOOP_SSH_OPTS=.*|export HADOOP_SSH_OPTS="-o StrictHostKeyChecking=no"| ' #{hadoop_env_file}}
  not_if "grep 'export HADOOP_SSH_OPTS=\"-o StrictHostKeyChecking=no\"' #{hadoop_env_file}"
end

# Set HADOOP_HOME in /etc/profile
execute 'set HADOOP_HOME in /etc/profile' do
  command %Q{echo 'export HADOOP_HOME=#{node[:hadoop][:hadoop_home_dir]} ; export HADOOP_HOME_WARN_SUPPRESS="TRUE"' >> /etc/profile}
  not_if "grep '^export HADOOP_HOME=' /etc/profile"
end

# Set JAVA_HOME in hadoop-env.sh
execute 'set JAVA_HOME in hadoop-env.sh' do
  command %Q{sed -i -e 's|# export JAVA_HOME=.*|export JAVA_HOME=/usr/lib/jvm/java-6-sun|' #{hadoop_env_file}}
  not_if "grep '^export JAVA_HOME=' #{hadoop_env_file}"
end

# Fix '-jvm server' option in bin/yarn and bin/hdfs. Have no idea why hadoop-0.23 add this option.
%w[bin/yarn bin/hdfs].each do |file|
  execute "fix '-jvm server' option in bin/yarn and bin/hdfs" do
    only_if do File.exists?("/usr/lib/hadoop/#{file}") end
    command %Q{sed -i -e 's|-jvm server|-server|' /usr/lib/hadoop/#{file}}
  end
end

# Set SLEEP_TIME
execute "Set SLEEP_TIME longer enough for the hadoop service process to stop completely" do
  command %Q{
    for service in /etc/init.d/hadoop-*; do
      sed -i -e 's|SLEEP_TIME=.*|SLEEP_TIME=#{node[:hadoop][:service_stop_time]}|' $service
    done
    true
  }
end
