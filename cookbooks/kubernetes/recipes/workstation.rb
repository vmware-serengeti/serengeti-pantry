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

step="build Kubernetes from source code"
set_bootstrap_action(step, '', true)
lock_file = "/opt/kubernetes/.kubernetes_installed.lock"
execute step do
  creates lock_file
  command %Q{
set -e
. /etc/profile.d/#{env_file}
if [ ! -e $GOPATH/bin/govc ]; then
  mkdir -p $GOPATH
  go get github.com/vmware/govmomi/govc
fi

gcp=$GOPATH/src/github.com/GoogleCloudPlatform
mkdir -p $gcp
cd $gcp
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

step="update salt master and minions"
set_bootstrap_action(step, '', true)
bash step do
  command %Q{
set -e
. /etc/profile.d/#{env_file}
. $KUBE_HOME/cluster/kube-env.sh
. $KUBE_HOME/cluster/$KUBERNETES_PROVIDER/util.sh
detect-master
(
  num_minions=$(kubecfg.sh list minions | wc -l)
  num_minions=$((num_minions - 3))
  if [ $num_minions != $NUM_MINIONS ]; then
    echo "echo New minions added or minions removed. Updating salt master and minions ..."
    echo "sudo salt '*' mine.update"
    echo "sudo salt --force-color '*' state.highstate"
  fi
) | kube-ssh ${KUBE_MASTER_IP} bash

# wait for minions 
sleep_time=3
timeout=60
while true; do
  num_minions=$(kubecfg.sh list minions | wc -l)
  num_minions=$((num_minions - 3))
  if [ $num_minions = $NUM_MINIONS ]; then exit; fi
  timeout=$((timeout - sleep_time));
  echo "Waiting for salt master to update the minions list. $timeout seconds left."
  if [ $timeout = 0 ]; then
    echo "WARNING: salt master hasn't detected the new minions, please check it later." > /dev/stderr
    exit 0
  fi
  sleep $sleep_time
done
}
end

step="deploy the Kubernetes cluster on master and minions nodes"
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

