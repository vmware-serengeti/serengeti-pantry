#
# Cookbook Name:: mesos
# Recipe:: install
#
# Copyright (C) 2013 Medidata Solutions, Inc.
# Portions Copyright (c) 2014 VMware, Inc. All Rights Reserved.
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

node.default['mesos']['zookeeper_server_list'] = zookeepers_ip

node.normal[:enable_standard_os_yum_repos] = true
include_recipe "hadoop_common::add_repo"

include_recipe 'java::default'

distro = node['platform']
distro_version = node['platform_version']

set_bootstrap_action(ACTION_INSTALL_PACKAGE, 'mesos', true)

case distro
when 'debian', 'ubuntu'
  include_recipe 'apt'
  %w( unzip default-jre-headless libcurl3 ).each do |pkg|
    package pkg do
      action :install
    end
  end

  if distro == 'debian'
    match = distro_version.match(/(\d{1})(\.?\d+)?/i)

    unless match.nil?
      major_version, _minor_version = match.captures
      distro_version = major_version
    end
  elsif distro == 'ubuntu'
    # For now we need to use the latest 13.x based deb
    # package until a trusty mesos deb is available
    # on mesosphere site.
    distro_version = '13.10' if distro_version == '14.04'
  end

  remote_file "#{Chef::Config[:file_cache_path]}/mesos.deb" do
    source "http://downloads.mesosphere.io/master/#{distro}/#{distro_version}/mesos_#{node['mesos']['version']}_amd64.deb"
    action :create
    not_if { ::File.exist? '/usr/local/sbin/mesos-master' }
  end

  dpkg_package 'mesos' do
    source "#{Chef::Config[:file_cache_path]}/mesos.deb"
    not_if { ::File.exist? '/usr/local/sbin/mesos-master' }
  end

#TODO: need chronos, marathon, docker .deb from somewhere

when 'rhel', 'centos', 'amazon', 'scientific'
  %w( unzip libcurl ).each do |pkg|
    yum_package pkg do
      action :install
    end
  end

  package 'mesos'
  package 'chronos' if node.role?('mesos_chronos')
  package 'marathon' if node.role?('mesos_marathon')
end

# Set init to 'stop' by default for all services
# Running mesos::master or mesos::slave recipe will reset to start as appropriate
services = %w[mesos-master mesos-slave]
services += %w[chronos] if node.role?('mesos_chronos')
services += %w[marathon] if node.role?('mesos_marathon')
services.each do |service|
  template "/etc/init/#{service}.conf" do
    source "#{service}.conf.erb"
    variables(
      action: 'stop',
    )
  end
end

#TODO: Need to explore debian-side Chronos/Marathon/Docker support
if distro == 'debian'
  bash 'reload-configuration-debian' do
    user 'root'
    code <<-EOH
    update-rc.d -f mesos-master remove
    EOH
    not_if { ::File.exist? '/usr/local/sbin/mesos-master' }
  end
else
  bash 'reload-configuration' do
    user 'root'
    code <<-EOH
    initctl reload-configuration
    EOH
    not_if { ::File.exist? '/usr/local/sbin/mesos-master' }
  end
end
