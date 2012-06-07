#
# Cookbook Name:: hadoop_cluster
# Recipe::        hadoop_conf_xml
#

#
#   Portions Copyright (c) 2012 VMware, Inc. All Rights Reserved.
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
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
