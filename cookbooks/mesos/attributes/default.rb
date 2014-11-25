#
#   Portions Copyright (c) 2012-2014 VMware, Inc. All Rights Reserved.
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

default['mesos']['version']                       = '0.21.0'
default['mesos']['common']['port']                = 5050
default['mesos']['common']['logs_dir']            = '/var/log/mesos'
default['mesos']['common']['logging_level']       = 'ERROR'
default['mesos']['common']['ulimit']              = '-n 16384'
default['mesos']['master']['cluster']             = node[:cluster_name]
default['mesos']['master']['zk']                  = '`cat /etc/mesos/zk`'
default['mesos']['slave']['work_dir']             = '/tmp/mesos'
default['mesos']['slave']['isolation']            = 'process'
default['mesos']['slave']['master']               = '`cat /etc/mesos/zk`'
default['mesos']['zookeeper_port']                = 2181
default['mesos']['zookeeper_path']                = node[:cluster_name]
default['mesos']['zookeeper_exhibitor_discovery'] = false
default['mesos']['zookeeper_exhibitor_url']       = nil
default['mesos']['set_ec2_hostname']              = true
# attributes under default['mesos']['slave'] are written to /etc/mesos-slave/$key = $value
default['mesos']['slave']['checkpoint']           = 'true'
default['mesos']['slave']['strict']               = 'false'
default['mesos']['slave']['recover']              = 'reconnect'

case node['platform']
when 'rhel', 'centos'
  default['java']['jdk_version'] = '7'
  default['mesos']['python_egg'] = "http://downloads.mesosphere.io/master/#{node['platform']}/6/mesos-#{node['mesos']['version']}-py2.6.egg"
when 'ubuntu'
  default['mesos']['python_egg'] = "http://downloads.mesosphere.io/master/ubuntu/13.04/mesos-#{node['mesos']['version']}-py2.7-linux-x86_64.egg"
when 'debian'
  default['mesos']['python_egg'] = "http://downloads.mesosphere.io/master/debian/7/mesos-#{node['mesos']['version']}-py2.7-linux-x86_64.egg"
else
  default['mesos']['python_egg'] = "http://downloads.mesosphere.io/master/ubuntu/13.04/mesos-#{node['mesos']['version']}-py2.7-linux-x86_64.egg"
end
