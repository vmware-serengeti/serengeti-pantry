#
#   Portions Copyright (c) 2012-2013 VMware, Inc. All Rights Reserved.
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
  action :nothing
end.run_action(:create)

user "mapr" do
  comment "MapR user"
  group "mapr"
  shell "/bin/bash"
  home  "/home/mapr"
  password "$1$iXcZZnYR$sp2moQUnZ5gEyTR5feeAm/"
  action :nothing
end.run_action(:create)

grant_sudo_to_user('mapr')

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

## Install MapR basic package
# mapr-client and mapr-core are conflicted, so only one can be installed
# mapr-client.i386 and mapr-client.x86_64 are conflicted in MapR 2.1.2+, so need to explicitly set arch x86_64
name = node.role?('mapr_client') ? 'mapr-client.x86_64' : 'mapr-core'
set_bootstrap_action(ACTION_INSTALL_PACKAGE, name, true)
# because we set arch in pacakge name 'mapr-client.x86_64', we have to use 'yum_package' instead of 'package'
yum_package name

# Applying patches. MapR 2.1.3 has a bug http://answers.mapr.com/questions/7177, which will be fixed in MapR 2.1.3.3+ and 3.0.1+.
filename = 'createTTVolume.sh'
filepath = "/opt/mapr/server/#{filename}"
cookbook_file filepath do
  only_if "rpm -q #{name} | grep -q 2.1.3"
  only_if { File.exist?(filepath) }
  source filename
  mode 0755
end

include_recipe 'mapr::nfs_utils' if node.role?('mapr_client') # so the user can mount nfs on mapr_client node

# Set JAVA_HOME
set_mapr_java_home

clear_bootstrap_action(true)
