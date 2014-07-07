#
#   Copyright (c) 2014 VMware, Inc. All Rights Reserved.
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

# get hbase.rootdir
def get_hbase_root_dir namespace
  rootdir = rootdir_conf
  if rootdir
    node.normal[:hbase][:hdfshome] = nil # TODO better to extra its value from rootdir
    node.normal[:hbase][:rootdir] = rootdir
  elsif node[:hbase][:rootdir].nil?
    Chef::Log.info('Generating value for hbase.rootdir')
    if is_primary_hbase_master
      # when multi hbase clusters point to the same HDFS, each HBase cluster should have different hbase.rootdir.
      # otherwise, hbase data are saved into the same HDFS dir, then cause conflict.
      suffix = Time.now.strftime("%Y%m%d%H%M%S%6N")
      node.normal[:hbase][:hdfshome] = "/hadoop/hbase/#{node[:cluster_name]}-#{suffix}"
      node.normal[:hbase][:rootdir] = "hdfs://#{namespace}#{node[:hbase][:hdfshome]}"
      provide_service(node[:hbase][:provider][:rootdir], {}, false) # don't run in ruby_block
    else
      # wait for hbase master to provide hbase.rootdir
      masternode = provider_for_service(node[:hbase][:provider][:rootdir])
      node.normal[:hbase][:hdfshome] = masternode[:hbase][:hdfshome]
      node.normal[:hbase][:rootdir] = masternode[:hbase][:rootdir]
    end
  end
  Chef::Log.info('hbase.rootdir is ' + node[:hbase][:rootdir])
  node[:hbase][:rootdir]
end

def set_sys_limit desc, user, ulimit_type, ulimit_value
  bash desc do
    not_if "egrep -q '#{user}.*#{ulimit_type}.*#{ulimit_value}' /etc/security/limits.conf"
    code <<EOF
      egrep -q '#{user}.*#{ulimit_type}' || ( echo '#{user} - #{ulimit_type}' >> /etc/security/limits.conf )
      sed -i "s/#{user}.*-.*#{ulimit_type}.*/#{user} - #{ulimit_type} #{ulimit_value}/" /etc/security/limits.conf
EOF
  end
end

def is_hbase_master
  node.role?("hbase_master")
end

def is_primary_hbase_master
  node.role?("hbase_master") and node[:facet_index] == 0
end

# wait for HBase Master daemon to be ready
def wait_for_hbase_master_service
  return if is_hbase_master
  run_in_ruby_block __method__ do
    wait_for_service(node[:hbase][:master_service_name])
  end
end

# return hbase.rootdir specified by the user, or nil if not specified
def rootdir_conf
  hbase_conf('hbase-site.xml', 'hbase.rootdir')
end

# Return user defined hbase configuration by file and attr
def hbase_conf(file, attr)
  all_hbase_conf[file][attr] rescue nil
end

# Return user defined hadoop configuration
def all_hbase_conf
  all_conf['hbase'] || {}
end
