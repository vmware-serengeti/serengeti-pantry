#
#   Copyright (c) 2012-2014 VMware, Inc. All Rights Reserved.
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

include_recipe 'chef_handler'

file = 'chef_handler_serengeti.rb'
cookbook_file "#{Chef::Config[:file_cache_path]}/#{file}" do
  source file
  mode 0600
end.run_action(:create)

chef_handler 'Chef::Handler::Serengeti' do
  source "#{Chef::Config[:file_cache_path]}/#{file}"
  supports :exception => true
  action :enable
end.run_action(:enable)
