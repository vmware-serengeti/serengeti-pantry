#
# Cookbook Name:: hadoop_cluster
# Recipe::        worker
#
# Copyright 2010, Infochimps, Inc
# Portions Copyright (c) 2012-2013 VMware, Inc. All Rights Reserved.
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
cluster_id = ""
cluster_id = "-clusterid #{node[:cluster_name]}" if node[:hadoop][:cluster_has_hdfs_ha_or_federation]
execute 'format namenode' do
  not_if { File.exists?('/mnt/hadoop/.namenode_formatted.log') }
  user 'hdfs'
  command %Q{
    yes 'Y' | hadoop namenode -format #{cluster_id}

    exit_status=$?
    if [ $exit_status -eq 0 ]; then touch /mnt/hadoop/.namenode_formatted.log ; fi
    exit $exit_status
  }
end
