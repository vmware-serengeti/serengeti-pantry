#
# Cookbook Name:: mesos
# Recipe:: master
#
# Copyright (C) 2013 Medidata Solutions, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#    http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

class ::Chef::Recipe
  include ::Mesos
end

include_recipe 'mesos::install'

template '/etc/default/mesos' do
  source 'mesos.erb'
  variables config: node['mesos']['common']
  notifies :run, 'bash[restart-mesos-master]', :delayed
end

template '/etc/default/mesos-master' do
  source 'mesos.erb'
  variables config: node['mesos']['master']
  notifies :run, 'bash[restart-mesos-master]', :delayed
end

pairs = {
  :quorum => 1,
  :logging_level => node['mesos']['common']['logging_level']
}
generate_mesos_param_files('master', pairs)

if node['mesos']['zookeeper_server_list'].count > 0
  zk_server_list = node['mesos']['zookeeper_server_list']
  zk_port = node['mesos']['zookeeper_port']
  zk_path = node['mesos']['zookeeper_path']
end

if node['mesos']['zookeeper_exhibitor_discovery'] && node['mesos']['zookeeper_exhibitor_url']
  zk_nodes = discover_zookeepers_with_retry(node['mesos']['zookeeper_exhibitor_url'])

  if zk_nodes.nil?
    Chef::Application.fatal!('Failed to discover zookeepers.  Cannot continue')
  end

  zk_server_list = zk_nodes['servers']
  zk_port = zk_nodes['port']
  zk_path = node['mesos']['zookeeper_path']
end

unless zk_server_list.nil? && zk_port.nil? && zk_path.nil?
  Chef::Log.info("Zookeeper Server List: #{zk_server_list}")
  Chef::Log.info("Zookeeper Port: #{zk_port}")
  Chef::Log.info("Zookeeper Path: #{zk_path}")

  template '/etc/mesos/zk' do
    source 'zk.erb'
    variables(
      zookeeper_server_list: zk_server_list,
      zookeeper_port: zk_port,
      zookeeper_path: zk_path,
    )
    notifies :run, 'bash[restart-mesos-master]', :delayed
  end
end

# If we are on ec2 set the public dns as the hostname so that
# mesos master redirection works properly.
if node.attribute?('ec2') && node['mesos']['set_ec2_hostname']
  bash 'set-aws-public-hostname' do
    user 'root'
    code <<-EOH
      PUBLIC_DNS=`wget -q -O - http://instance-data.ec2.internal/latest/meta-data/public-hostname`
      hostname $PUBLIC_DNS
      echo $PUBLIC_DNS > /etc/hostname
      HOSTNAME=$PUBLIC_DNS  # Fix the bash built-in hostname variable too
    EOH
    not_if 'hostname | grep amazonaws.com'
  end
end

set_bootstrap_action(ACTION_START_SERVICE, 'mesos-master', true)

services = %w[mesos-master]
services += %w[chronos] if node.role?('mesos_chronos')
services += %w[marathon] if node.role?('mesos_marathon')
services.each do |service|
  # Set init to 'start' by default for mesos master.
  # This ensures that mesos-master is started on restart
  template "/etc/init/#{service}.conf" do
    source "#{service}.conf.erb"
    variables(
      action: 'start',
    )
    notifies :run, "bash[reload-configuration-#{service}]"
  end

  if node['platform'] == 'debian'
    bash "reload-configuration-#{service}" do
      action :nothing
      user 'root'
      code <<-EOH
       update-rc.d #{service} defaults
      EOH
    end
  else
    bash "reload-configuration-#{service}" do
      action :nothing
      user 'root'
      code <<-EOH
       initctl reload-configuration
      EOH
    end
  end

  if node['platform'] == 'debian'
    bash "start-#{service}" do
      user 'root'
      code <<-EOH
       service #{service} start
      EOH
      not_if "service #{service} status | grep start/running"
    end
  else
    bash "start-#{service}" do
      user 'root'
      code <<-EOH
       start #{service}
      EOH
      not_if "status #{service} | grep start/running"
    end
  end

  if node['platform'] == 'debian'
    bash "restart-#{service}" do
      action :nothing
      user 'root'
      code <<-EOH
       service #{service} restart
      EOH
      not_if "service #{service} status | grep stop/waiting"
    end
  else
    bash "restart-#{service}" do
      action :nothing
      user 'root'
      code <<-EOH
       restart #{service}
      EOH
      not_if "status #{service} | grep stop/waiting"
    end
  end
end