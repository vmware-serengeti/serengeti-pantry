#
#   Copyright (c) 2012-2013 VMware, Inc. All Rights Reserved.
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

## Install postgresql database
include_recipe 'postgresql::server'

package "postgresql-jdbc"
execute "copy postgresql-jdbc to hive lib" do
  not_if { File.exist?("#{node[:hive][:home_dir]}/lib/postgresql-jdbc-8.1.407.jar") }
  command %Q{
    cp /usr/share/java/postgresql-jdbc-8.1.407.jar #{node[:hive][:home_dir]}/lib/
  }
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
execute "initialize postgresql db" do
  only_if "sudo service postgresql status"
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

schema_file_path = "#{node[:hive][:home_dir]}/src/metastore/scripts/upgrade/postgres/hive-schema-0.7.0.postgres.sql"
execute "fix hive server sql bug for postgresql metastore on GreenPlum HD" do
  only_if "grep -q 'bit(1)' #{schema_file_path} 2>/dev/null"
  command %Q{sudo sed -i 's|bit(1)|boolean|' #{schema_file_path}}
end

# Hive 0.9.0 binary package doesn't contain the postgres sql file
schema_file_path_ver090 = "#{scripts_home}/hive-schema-0.9.0.postgres.sql"
template schema_file_path_ver090 do
  only_if 'head -1 /usr/lib/hive/RELEASE_NOTES.txt 2>/dev/null | grep -q 0.9'
  source 'hive-schema-0.9.0.postgres.sql.erb'
  mode '0644'
end

# TODO: hive-schema-[version].postgres.sql should be adapt to the hive version installed on the node
# but the sql file for hive 0.8.0 in hive svn trunk doesn't work for hive-0.8.1: http://svn.apache.org/viewvc/hive/trunk/metastore/scripts/upgrade/postgres/hive-schema-0.8.0.postgres.sql?revision=1334537&view=markup
log = "#{node[:hive][:log_dir]}/.hive_metastore_schema_imported.log"
execute "Import metastore schema" do
  only_if "sudo service postgresql status"
  not_if { File.exists?(log) }
  user "hive"
  cwd "#{node[:hive][:home_dir]}"
  command %Q{
    if [ -f #{schema_file_path_ver090} ]; then
      schema_file=#{schema_file_path_ver090}
    elif [ -f #{schema_file_path} ]; then
      schema_file=#{schema_file_path}
    else
      echo "WARNING: Can't find sql file to create Hive metastore tables. Will let Hive create them automatcially."
      exit 0
    fi
    echo "Use $schema_file to create Hive metastore tables"

    psql -U hive -d metastore_db -f $schema_file

    exit_status=$?
    if [ $exit_status -eq 0 ]; then touch #{log} ; fi
    exit $exit_status
 }
end
