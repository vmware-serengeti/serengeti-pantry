#
# Cookbook Name:: hadoop
# Recipe::        worker
#
# Copyright 2010, Infochimps, Inc
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Format Namenode
#
execute 'format_namenode **REMOVE FROM RUNLIST ON SUCCESSFUL BOOTSTRAP**' do
  not_if "service #{node[:hadoop][:namenode_service_name]} status"
  not_if { File.exists?('/mnt/hadoop/.namenode_formatted.log') }
  user 'hdfs'
  command %q{
    yes 'Y' | hadoop namenode -format

    exit_status=$?
    if [ $exit_status -eq 0 ]; then touch /mnt/hadoop/.namenode_formatted.log ; fi
    exit $exit_status
  }

  # creates '/mnt/hadoop/.namenode_formatted.log'
  # notifies  :restart, resources(:service => "#{node[:hadoop][:hadoop_handle]}-namenode")
end
