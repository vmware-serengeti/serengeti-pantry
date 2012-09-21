#
#   Copyright (c) 2012 VMware, Inc. All Rights Reserved.
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

module HadoopCluster
  def jobtracker_ip_conf
    jobtracker_uri_conf[0] rescue nil
  end

  def jobtracker_port_conf
    jobtracker_uri_conf[1] rescue nil
  end

  # Return user defined jobtracker uri
  def jobtracker_uri_conf
    uri = hadoop_conf('mapred-site.xml', 'mapred.job.tracker')
    # mapred.job.tracker is something like : '192.168.1.100:8021'
    uri ? uri.split(':') : nil rescue nil
  end

  def namenode_ip_conf
    namenode_uri_conf[0] rescue nil
  end

  def namenode_port_conf
    namenode_uri_conf[1] rescue nil
  end

  # Return user defined namenode uri
  def namenode_uri_conf
    uri = hadoop_conf('core-site.xml', 'fs.default.name')
    # fs.default.name is something like : 'hdfs://192.168.1.100:8020'
    uri ? uri.split('://')[1].split(':') : nil rescue nil
  end

  # Return user defined hadoop configuration by file and attr
  def hadoop_conf(file, attr)
    all_hadoop_conf[file][attr] rescue nil
  end

  # Return user defined hadoop configuration
  def all_hadoop_conf
    all_conf['hadoop'] || {}
  end

  # Return user defined cluster configuration
  def all_conf
    conf = node['cluster_configuration'] || {} rescue conf = {}
    conf.dup
  end
end

class Chef::Recipe ; include HadoopCluster ; end
class Chef::Resource::Directory ; include HadoopCluster ; end
