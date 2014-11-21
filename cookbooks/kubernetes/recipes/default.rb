#
# Cookbook Name:: kubernetes
# Recipe:: default
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

conf = node['cluster_configuration']['kubernetes']['env'] || {} rescue conf = {}

if !conf['WORKSTATION_PUB_KEY'].nil? and !conf['WORKSTATION_PUB_KEY'].empty?
  username = 'serengeti'
  authorized_keys_file = "/home/#{username}/.ssh/authorized_keys"
  execute "add public key to authorized_keys" do
    user username
    command %Q{
      if ! grep '#{conf['WORKSTATION_PUB_KEY']}' #{authorized_keys_file} 
      then
        echo #{conf['WORKSTATION_PUB_KEY']} >> #{authorized_keys_file}
      fi
    }
    action :nothing
  end.run_action(:run)
end
