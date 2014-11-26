#
# Cookbook Name:: kubernetes
# Recipe:: workstation
#
#   Copyright (c) 2014 VMware, Inc. All Rights Reserved.
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

def template_vars 
  vars = {
    :cluster_name => node[:cluster_name],
    :minions_num  => all_nodes_count({"role" => "kubernetes_minion"})
  }

  vars
end

username = 'serengeti'
rsa_file = "/home/#{username}/.ssh/id_rsa"
execute "generate ssh keypair for user #{username}" do
  not_if { File.exist?(rsa_file) }
  user username
  command "ssh-keygen -t rsa -N '' -f #{rsa_file}"
  action :nothing
end.run_action(:run)

Chef::Log.info "Setting Kubernetes env variables"
env_file = 'kubernetes.sh'
vars = template_vars
template "/etc/profile.d/#{env_file}" do
  owner "serengeti"
  group "root"
  mode  "0750"
  variables vars
  source "#{env_file}.erb"
end

execute "install govc" do
  not_if 'which govc'
  command %Q{
set -e
. /etc/profile.d/#{env_file}
if [ ! -e $GOPATH/bin/govc ]; then
  mkdir -p $GOPATH
  go get github.com/vmware/govmomi/govc
  mkdir -p $GOPATH/src/github.com/GoogleCloudPlatform
fi
}
end

lock_file = "/opt/kubernetes/.kubernetes_installed.lock"
if node[:kubernetes][:install_from_source] and !File.exist?(lock_file)
  step="Installing Kubernetes from source code"
  set_bootstrap_action(step, '', true)
  execute step do
    creates lock_file
    command %Q{
set -e
. /etc/profile.d/#{env_file}

cd $GOPATH/src/github.com/GoogleCloudPlatform
if [ ! -e kubernetes ]; then
  git clone https://github.com/jessehu/kubernetes.git
  cd kubernetes
  # Build source
  hack/build-go.sh
else
  cd kubernetes
  git pull
fi

# Build a release (argument is the instance prefix)
release/build-release.sh $KUBE_CLUSTER_NAME

touch {$lock_file}
}
  end
elsif node[:kubernetes][:install_from_tarball] and !File.exist?(node[:kubernetes][:home_dir])
  step="Installing Kubernetes from binary tarball"
  set_bootstrap_action(step, '', true)
  url = current_distro['tarball']
  ver = distro_version
  install_from_release('kubernetes') do
    release_url   url
    version       ver
    home_dir      node[:kubernetes][:home_dir]
    action        [:install]
    has_binaries  []
  end
end

## Patch Kubernetes vSphere plugin to support Serengeti
files = %w[config-default.sh util.sh templates/hostname.sh]
files.each do |file|
  template "#{node[:kubernetes][:home_dir]}/cluster/vsphere/#{file}" do
    owner "root"
    mode file.end_with?('.sh') ? "0755" : "0644"
    source "vsphere/#{file}.erb"
  end
end

step="Deploying Kubernetes master and minions nodes"
set_bootstrap_action(step, '', true)
execute step do
  user 'serengeti'
  environment ({'HOME' => '/home/serengeti'})
  command %Q{
. /etc/profile.d/#{env_file}
cd $KUBE_HOME
kube-up.sh 1>~/kube.log 2>&1
}
end
