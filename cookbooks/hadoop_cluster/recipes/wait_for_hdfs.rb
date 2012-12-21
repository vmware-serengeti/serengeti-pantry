#
# Cookbook Name:: hadoop_cluster
# Recipe::        wait_for_hdfs
#
# Copyright (c) 2012 VMware, Inc. All Rights Reserved.
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

execute "wait_for_namenode" do
  action :nothing
  command %Q{
    i=0
    while [ $i -le #{node[:hadoop][:namenode_wait_for_safemode_timeout]} ]
    do
      sleep 5
      if `hadoop dfsadmin -safemode get | grep -q OFF` ; then
        echo "namenode safemode is off"
        exit
      fi
      (( i+=5 ))
      echo "Wait until namenode leaves safemode. Already wait for $i seconds."
    done
    echo "Namenode stucks in safemode. Will explictlly tell it leave safemode."
    hadoop dfsadmin -safemode leave
  }
end

ruby_block "wait_for_hdfs" do
  action :nothing
  block do
    Chef::Log.info('wait until the datanodes daemon are started.')
    all_providers_for_service(node[:hadoop][:datanode_service_name])
    Chef::Log.info('the datanodes daemon are started and contacted with namenode daemon.')
    Chef::Log.info('wait until namenode adds the datanodes and are able to place replica.')
    sleep(60)
    resources(:execute => "wait_for_namenode").run_action(:run)
    Chef::Log.info('HDFS is ready to place replica now.')
  end
end
