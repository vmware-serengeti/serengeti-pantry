#
# Cookbook Name:: hadoop_cluster
# Recipe::        make_standard_hdfs_dirs
#
# Copyright 2010, Infochimps, Inc.
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
# Make the standard HDFS directories:
#
#   /tmp
#   /user
#   /user/hive/warehouse
#
# and
#
#   /user/USERNAME
#
# for each user in the 'supergroup' group.
#
# I'd love feedback on whether this can be made less kludgey,
# and whether the logic for creating the user dirs makes sense.
#
# Also, quoting Tom White:
#   "The [chmod +w] is questionable, as it allows a user to delete another
#    user. It's needed to allow users to create their own user directories"
#
execute 'create common user dirs on HDFS' do
  only_if "service #{node[:hadoop][:namenode_service_name]} status"
  #only_if "hadoop dfsadmin -safemode wait | grep -q OFF"
  not_if { File.exists?('/mnt/hadoop/.made_inital_dirs.log') }
  #creates '/mnt/hadoop/.made_inital_dirs.log' # this doesn't work; may be a bug of 'execute' resource ?
  user 'hdfs'
  command %q{
    hadoop fs -chmod 775           /
    hadoop fs -chown hdfs:hadoop   /

    hadoop fs -mkdir               /hadoop
    hadoop fs -chmod 775           /hadoop
    hadoop fs -chown hdfs:hadoop   /hadoop

    hadoop fs -mkdir               /hadoop/system
    hadoop fs -chmod 775           /hadoop/system
    hadoop fs -chown mapred:hadoop /hadoop/system

    hadoop fs -mkdir               /hadoop/system/mapred
    hadoop fs -chmod 775           /hadoop/system/mapred
    hadoop fs -chown mapred:hadoop /hadoop/system/mapred

    hadoop fs -mkdir               /hadoop/hbase
    hadoop fs -chmod 775           /hadoop/hbase
    hadoop fs -chown hbase:hadoop  /hadoop/hbase

    hadoop_users=/user/"`grep supergroup /etc/group | cut -d: -f4 | sed -e 's|,| /user/|g'`"
    if [ "$hadoop_users" = "/user/" ]; then hadoop_users='' ; fi
    hadoop_users="$hadoop_users"
    hadoop fs -mkdir     /tmp /user /user/hive/ /user/hive/warehouse $hadoop_users;
    hadoop fs -chmod a+w /tmp /user /user/hive/ /user/hive/warehouse;
    for user in $hadoop_users ; do
      hadoop fs -chown ${user#/user/} $user;
    done ;

    hadoop fs -mkdir -p /tmp/hadoop-yarn/staging
    hadoop fs -chmod -R 777 /tmp/hadoop-yarn

    exit_status=$?
    if [ $exit_status -eq 0 ]; then touch /mnt/hadoop/.made_inital_dirs.log ; fi
    exit $exit_status
  }
end
