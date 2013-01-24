#
#   Portions Copyright (c) 2012 VMware, Inc. All Rights Reserved.
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

# Set up required repos for RHEL/CentOS
include_recipe "hadoop_common::add_repo"


# MapR 2.x requires mysql-server-5.1+ and some other packages in EPEL yum repo.
# CentOS 5.6 only has mysql-server-5.0.95, and REMI yum repo provides mysql-server-5.5.
# For now, we have added mysql-server-5.5 and some EPEL rpms into Serengeti internal yum server,
# so will not add EPEL and REMI yum repo here.
# If you are using this cookbook outside of Serengeti, please turn on the code snippet below.
if false && is_connected_to_internet
  # Install EPEL yum repository
  remote_file "/tmp/epel-release-5-4.noarch.rpm" do
    source "http://dl.fedoraproject.org/pub/epel/5/x86_64/epel-release-5-4.noarch.rpm"
  end

  rpm_package "epel" do
    action :install
    source "/tmp/epel-release-5-4.noarch.rpm"
  end

  # Install remi-release yum repository
  remote_file "/tmp/remi-release-5.rpm" do
    source "http://rpms.famillecollet.com/enterprise/remi-release-5.rpm"
  end

  rpm_package "remi-release-5" do
    action :install
    source "/tmp/remi-release-5.rpm"
  end

  execute "enable remi.repo" do
    command %Q{
      sed -i "s|enabled=0|enabled=1|" /etc/yum.repos.d/remi.repo
    }
  end
end

## Disable SELinux - should be able to re-enable after install
f = Chef::Util::FileEdit.new('/etc/selinux/config')
f.search_file_replace_line('^SELINUX=', 'SELINUX=disabled')
f.write_file

file "/selinux/enforce" do
  content "0"
end

# Turn off iptables. Should be able to just open up required ports.
service "iptables" do
  action [:stop, :disable]
end

## Create mapr group and user
group "mapr" do
  gid 401
  action :nothing
end.run_action(:create)

user "mapr" do
  comment "MapR user"
  uid 401
  group "mapr"
  shell "/bin/bash"
  home  "/home/mapr"
  password "$1$iXcZZnYR$sp2moQUnZ5gEyTR5feeAm/"
  action :nothing
end.run_action(:create)

# Generate SSH keypair for MapR user
generate_ssh_rsa_keypair('mapr')

# See http://www.mapr.com/doc/display/MapR/Requirements+for+Installation#RequirementsforInstallation-keyless
setup_keyless_ssh_for_role('mapr_webserver')


# Install packages required by MapR
# See all packages on http://www.mapr.com/doc/display/MapR/Packages+and+Dependencies+for+MapR+Version+2.x
# only install packages below because other packages will be installed automatically when installing mapr-core.
package "sendmail"
package "unzip"
package "pdsh"

# Install MapR basic package
# mapr-client and mapr-core are conflicted
name = node.role?('mapr_client') ? 'mapr-client' : 'mapr-core'
set_bootstrap_action(ACTION_INSTALL_PACKAGE, name, true)
package name

# Set JAVA_HOME
set_mapr_java_home
