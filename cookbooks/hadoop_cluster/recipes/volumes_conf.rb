#
# Cookbook Name:: hadoop_cluster
# Recipe::        volumes_conf
#

#
# Portions Copyright (c) 2012 VMware, Inc. All Rights Reserved.
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

include_recipe "hadoop_common::mount_disks"

# Directory /mnt/hadoop is used across this cookbook
make_hadoop_dir '/mnt/hadoop', 'hdfs'

local_hadoop_dirs.each do |dir|
  make_hadoop_dir dir, 'hdfs'
end

# Important: In CDH3 Beta 3, the mapred.system.dir directory must be located inside a directory that is owned by mapred. For example, if mapred.system.dir is specified as /mapred/system, then /mapred must be owned by mapred. Don't, for example, specify /mrsystem as mapred.system.dir because you don't want / owned by mapred.
#
# Directory             Owner           Permissions
# dfs.name.dir          hdfs:hadoop     drwx------
# dfs.data.dir          hdfs:hadoop     drwxr-xr-x
# mapred.local.dir      mapred:hadoop   drwxr-xr-x
# mapred.system.dir     mapred:hadoop   drwxr-xr-x

#
# Physical directories for HDFS files and metadata
#
dfs_name_dirs.each{      |dir| make_hadoop_dir(dir, 'hdfs',   "0700") }
dfs_data_dirs.each{      |dir| make_hadoop_dir(dir, 'hdfs',   "0755") }
fs_checkpoint_dirs.each{ |dir| make_hadoop_dir(dir, 'hdfs',   "0700") }
mapred_local_dirs.each{  |dir| make_hadoop_dir(dir, 'mapred', "0755") }

