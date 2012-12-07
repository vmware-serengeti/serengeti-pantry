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
  only_if "sudo service postgresql status"
  not_if { File.exists?("#{node[:postgresql][:dir]}/.initialized_postgresql_db.log") }
  user "postgres"
  cwd "/var/lib/pgsql"
  command %Q{
    psql -U postgres postgres -f #{initialize_postgresql_db_path}

    exit_status=$?
    if [ $exit_status -eq 0 ]; then touch #{node[:postgresql][:dir]}/.initialized_postgresql_db.log ; fi
    exit $exit_status
 }
end

schema_file_path = "#{node[:hive][:home_dir]}/src/metastore/scripts/upgrade/postgres/hive-schema-0.7.0.postgres.sql"

execute "fix hive server sql bug for postgresql metastore on GreenPlum HD" do
  only_if "grep 'bit(1)' #{schema_file_path} > /dev/null"
  command %Q{sudo sed -i 's|bit(1)|boolean|' #{schema_file_path}}
end

# TODO: hive-schema-[version].postgres.sql should be adapt to the hive version installed on the node
# but the sql file for hive 0.8.0 in hive svn trunk doesn't work for hive-0.8.1: http://svn.apache.org/viewvc/hive/trunk/metastore/scripts/upgrade/postgres/hive-schema-0.8.0.postgres.sql?revision=1334537&view=markup
execute "Import metastore schema" do
  only_if "sudo service postgresql status"
  only_if { File.exists?(schema_file_path) }
  not_if { File.exists?("#{node[:hive][:log_dir]}/.imported_metastore_schema.log") }
  user "hive"
  cwd "#{node[:hive][:home_dir]}"
  command %Q{
    psql -U hive -d metastore_db -f #{schema_file_path}

    exit_status=$?
    if [ $exit_status -eq 0 ]; then touch #{node[:hive][:log_dir]}/.imported_metastore_schema.log ; fi
    exit $exit_status
 }
end

package "postgresql-jdbc" do
  # version "8.1.407"
end

execute "Copy postgresql-jdbc to hive lib" do
  command %Q{
    cp /usr/share/java/postgresql-jdbc-8.1.407.jar #{node[:hive][:home_dir]}/lib/
  }
end
