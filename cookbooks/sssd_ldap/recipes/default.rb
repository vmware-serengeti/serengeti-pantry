#
# Cookbook Name:: sssd_ldap
# Recipe:: default
#
# Copyright 2013-2014, Limelight Networks, Inc.
# Portions Copyright (c) 2014 VMware, Inc. All Rights Reserved.
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

package 'sssd' do
  action :install
end

if node['platform_family'] == 'rhel' and node['platform_version'].to_f < 6
  if node['sssd_ldap']['ldap_sudo']
    # The libsss_sudo rpm on https://repos.fedorapeople.org/repos/jhrozek/sssd-libs/epel-5/x86_64/ doesn't work
    Chef::Log.warn('RHEL/CentOS 5 does not provide official libsss_sudo rpm. SSSD LDAP sudo will be disabled.')
    node.normal['sssd_ldap']['ldap_sudo'] = false
  end
end

if node['sssd_ldap']['ldap_sudo']
  package 'libsss_sudo' do
    action :install
  end

  vars = {
    :sss => 'sss',
    :sudo => ', sudo'
  }
else
  vars = {
    :sss => '',
    :sudo => ''
  }
end

# Only run on RHEL
if platform_family?('rhel')

  # authconfig allows cli based intelligent manipulation of the pam.d files
  package 'authconfig' do
    action :install
  end

  # Have authconfig enable SSSD in the pam files
  execute 'authconfig' do
    command "authconfig #{node['sssd_ldap']['authconfig_params']}"
    action :nothing
  end

  # Make sure sss is added for auth in nsswitch
  template '/etc/nsswitch.conf' do
    source 'nsswitch.conf.erb'
    owner 'root'
    group 'root'
    mode '0644'
    variables vars
  end

end

# sssd automatically modifies the PAM files with pam-auth-update and /etc/nsswitch.conf, so all that's left is to configure /etc/sssd/sssd.conf
template '/etc/sssd/sssd.conf' do
  source 'sssd.conf.erb'
  owner 'root'
  group 'root'
  mode '0600'
  variables vars
  if platform_family?('rhel')
    notifies :run, 'execute[authconfig]', :immediately # this needs to run immediately so it doesn't happen after sssd service block below, or sssd is not running when recipe completes
  else
    notifies :restart, 'service[sssd]', :immediately
  end
end

service 'sssd' do
  supports :status => true, :restart => true, :reload => true
  action [:enable, :start]
  provider Chef::Provider::Service::Upstart if node['platform'] == 'ubuntu' && node['platform_version'].to_f >= 13.04
end

# nscd caching will break sssd and is not necessary
service 'nscd' do
  supports :status => true, :restart => true, :reload => true
  action [:disable, :stop]
  provider Chef::Provider::Service::Upstart if node['platform'] == 'ubuntu' && node['platform_version'].to_f >= 13.04
end
