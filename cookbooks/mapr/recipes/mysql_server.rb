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

include_recipe 'mapr::prereqs'

include_recipe 'mysql::server'

set_bootstrap_action('Initializing MapR metrics database', '', true)

create_mapr_user_sql = "/opt/mapr/bin/create_mapr_user.sql"
template create_mapr_user_sql do
  source "mapr_user.sql.erb"
  owner  "root"
  group  node['mysql']['root_group']
  mode  "0600"
  action :create
end

mysql_command = "#{node['mysql']['mysql_bin']} -u root -p'#{node['mysql']['server_root_password']}'"
lock_file = '/opt/mapr/bin/.initialize_metrics_database.log'
execute "create the database schema for the Metrics database" do
  not_if { File.exist?(lock_file) }
  command %Q{
    #{mysql_command} < /opt/mapr/bin/setup.sql
    #{mysql_command} < #{create_mapr_user_sql}

    exit_status=$?
    if [ $exit_status -eq 0 ]; then touch #{lock_file}; fi
    exit $exit_status
  }
end

# Register with cluster_service_discovery
provide_service(node[:mapr][:mysql_service_name])

clear_bootstrap_action