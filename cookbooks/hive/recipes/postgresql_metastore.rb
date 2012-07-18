#
#   Copyright (c) 2012 VMware, Inc. All Rights Reserved.
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

initialize_postgresql_db_path =  "#{node[:postgresql][:dir]}/initialize_postgresql_db.sql"

template initialize_postgresql_db_path do
  source "initialize_postgresql_db.sql.erb"
  owner "postgres"
  group "postgres"
  mode 0600
end

execute "Initialize postgresql db" do
  command %Q{
    psql -U postgres -h #{node[:ipaddress]} postgres -f #{initialize_postgresql_db_path}
  }
end

package "postgresql-jdbc" do
  not_if "rpm -q postgresql-jdbc"
  action :install
end

execute "Copy postgresql-jdbc to hive lib" do
  command %Q{
    cp /usr/share/java/postgresql-jdbc-8.1.407.jar #{node[:hive][:home_dir]}/lib/
  }
end
