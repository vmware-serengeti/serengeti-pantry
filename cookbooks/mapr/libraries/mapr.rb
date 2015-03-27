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

module MapR

  # whether this node has mapr_zookeeper role
  def is_mapr_zookeeper
    node.role?('mapr_zookeeper')
  end

  def is_mapr_cldb
    node.role?('mapr_cldb')
  end

  def is_mapr_mysql_server
    node.role?('mapr_mysql_server')
  end

  def is_compute_only_node
    node.role?('mapr_tasktracker') and !node.role?('mapr_nfs')
  end

  def cldbs_address
    all_provider_public_ips_for_role('mapr_cldb').join(",")
  end

  def zookeepers_address
    all_provider_public_ips_for_role('mapr_zookeeper').join(",")
  end

  def resourcemanagers_address
    all_provider_public_ips_for_role('mapr_resourcemanager').join(",")
  end

  # there should be only one History Server
  def historyserver_address
    all_provider_public_ips_for_role('mapr_historyserver').first
  end

  # Wait until Zookeepers daemons have started
  def wait_for_zookeeper_nodes
    if !is_mapr_zookeeper
      run_in_ruby_block('wait_for_zookeeper_nodes') do
        zookeeper_count = all_nodes_count({"role" => "mapr_zookeeper"})
        all_provider_public_ips(node[:mapr][:zookeeper_service_name], true, zookeeper_count)
      end
    end
  end

  # Wait until mysql server daemon has started
  def wait_for_mysql_server
    if !is_mapr_mysql_server
      run_in_ruby_block('wait_for_mysql_server') do
        wait_for_service(node['mapr']['mysql_service_name'])
      end
    end
  end

  # Config JAVA_HOME for MapR
  def set_mapr_java_home
    set_java_home('/opt/mapr/conf/env.sh')
  end

  def setup_keyless_ssh_for_role(role)
    keys = rsa_pub_keys_of_user('mapr', role)
    file '/home/mapr/.ssh/authorized_keys' do
      owner 'mapr'
      group 'mapr'
      mode  '0640'
      content keys.join("\n")
      action :nothing
    end.run_action(:create)
  end

  def mysql_password
    # this key equals to key for node['mysql']['server_root_password'] ; see http://wiki.opscode.com/display/chef/Search#Search-FieldNameSyntax
    key = 'mysql_server_root_password'
    role = 'mapr_mysql_server'
    node = provider_for(key, {"role" => role, key => "*"})
    node['mysql']['server_root_password']
  end

  def mysql_connection_params
    @mysql_connection_params ||= {
      :host => provider_ip_for_role('mapr_mysql_server'),
      :port => node['mapr']['mysql_port'],
      :user => node['mapr']['mysql_username'],
      :pwd => mysql_password,
      :schema => 'metrics'
    }
  end

end

class Chef::Recipe   ; include MapR; end
class Chef::Resource ; include MapR; end