#
# Cookbook Name:: hadoop_cluster
# Recipe::        hadoop_conf_xml
#
class Chef::Recipe; include HadoopCluster ; end

#
# Generate Hadoop xml configuration files in $HADDOP_HOME/conf/
#

template_variables = hadoop_template_variables
Chef::Log.debug template_variables.inspect

files = %w[core-site.xml hdfs-site.xml mapred-site.xml hadoop-env.sh fairscheduler.xml raw_settings.yaml hadoop-metrics.properties]
files.each do |conf_file|
  template "/etc/hadoop/conf/#{conf_file}" do
    owner "root"
    mode "0644"
    variables(template_variables)
    source "#{conf_file}.erb"
  end
end

template "/etc/default/#{node[:hadoop][:hadoop_handle]}" do
  owner "root"
  mode "0644"
  variables(template_variables)
  source "etc_default_hadoop.erb"
end
