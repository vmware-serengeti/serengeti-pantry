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

# If this node is created by Serengeti 2.1.x, postgresql 8.4.17 was already installed.
# Then we will not reinstall postgresql 9.4 provided by Serengeti 2.2.x.
# We can do the migration from postgresql 8.4.17 to 9.4 in future.
if system('/usr/bin/psql -V | grep 8.4.17')
  return
end

## Install postgresql database
include_recipe 'postgresql::server'

include_recipe 'postgresql::jdbc'

link "put postgresql-jdbc.jar into hive lib dir" do
  target_file "#{node[:hive][:home_dir]}/lib/postgresql-jdbc.jar"
  to node['postgresql']['jdbc']['jar']
end

## Initialize hive metastore
scripts_home = "#{node[:hive][:home_dir]}/scripts"
directory scripts_home do
  mode '0755'
  action :create
end

initialize_postgresql_db_path =  "#{scripts_home}/initialize_postgresql_db.sql"
template initialize_postgresql_db_path do
  source "initialize_postgresql_db.sql.erb"
  mode '0644'
end

log = "#{node[:postgresql][:dir]}/.hive_postgresql_db_initialized.log"
execute "initialize postgresql db for hive" do
  not_if { File.exists?(log) }
  user "postgres"
  cwd "/var/lib/pgsql"
  command %Q{
    psql -U postgres postgres -f #{initialize_postgresql_db_path}

    exit_status=$?
    if [ $exit_status -eq 0 ]; then touch #{log} ; fi
    exit $exit_status
 }
end

schema_file_path_ver070 = "#{node[:hive][:home_dir]}/src/metastore/scripts/upgrade/postgres/hive-schema-0.7.0.postgres.sql"
execute "fix hive server sql bug for postgresql metastore on GreenPlum HD" do
  only_if { File.exists?(schema_file_path_ver070) }
  only_if "grep -q 'bit(1)' #{schema_file_path_ver070} 2>/dev/null"
  command %Q{sudo sed -i 's|bit(1)|boolean|' #{schema_file_path_ver070}}
end

# Hive 0.9.0 binary package doesn't contain the postgres sql file
schema_file_path_ver090 = "#{scripts_home}/hive-schema-0.9.0.postgres.sql"
template schema_file_path_ver090 do
  only_if { node[:hive][:version].start_with?("0.9") }
  source 'hive-schema-0.9.0.postgres.sql.erb'
  mode '0644'
end

# Hive 0.10.0 metastore schema file for postgres in HW 1.2 has bugs, we have to use template schema file
# Hive 0.11.0 in HW 1.3 is also using hive-schema-0.10.0.postgres.sql
schema_file_path_ver0100 = "#{scripts_home}/hive-schema-0.10.0.postgres.sql"
template schema_file_path_ver0100 do
  only_if { node[:hive][:version].start_with?("0.10") || node[:hive][:version].start_with?("0.11") }
  source 'hive-schema-0.10.0.postgres.sql.erb'
  mode '0644'
end

log = "#{node[:hive][:log_dir]}/.hive_metastore_schema_imported.log"
execute "Import hive metastore schema" do
  not_if { File.exists?(log) }
  user "hive"
  cwd "#{node[:hive][:home_dir]}"
  command %Q{
    # the expected postgres sql file for hive
    schema_file_path=#{node[:hive][:home_dir]}/scripts/metastore/upgrade/postgres/hive-schema-`cat #{node[:hive][:home_dir]}/version`.postgres.sql
    # Use hive-schema-0.13.0.postgres.sql for Hive 0.13.1 in CDH 5.2 because Hive 0.13.1 doesn't contain hive-schema-0.13.1.postgres.sql
    schema_file_path_minor=`echo ${schema_file_path} | sed -e 's/[[:digit:]]\\+.postgres.sql/*.postgres.sql/'`
    schema_file_path_minor=`ls ${schema_file_path_minor} | tail -1`

    if [ -f $schema_file_path ]; then
      schema_file=$schema_file_path
    elif [ -f $schema_file_path_minor ]; then
      schema_file=$schema_file_path_minor
    elif [ -f #{schema_file_path_ver0100} ]; then
      schema_file=#{schema_file_path_ver0100}
    elif [ -f #{schema_file_path_ver090} ]; then
      schema_file=#{schema_file_path_ver090}
    elif [ -f #{schema_file_path_ver070} ]; then
      schema_file=#{schema_file_path_ver070}
    else
      echo "WARNING: Can't find sql file to create Hive metastore tables. Will let Hive create them automatcially."
      exit 0
    fi
    echo "Use $schema_file to create Hive metastore tables"

    psql -U #{node[:hive][:metastore_user]} -d #{node[:hive][:metastore_db]} -f $schema_file

    exit_status=$?
    if [ $exit_status -eq 0 ]; then touch #{log} ; fi
    exit $exit_status
 }
end
