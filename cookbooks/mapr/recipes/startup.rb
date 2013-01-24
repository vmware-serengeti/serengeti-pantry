#
#   Copyright (c) 2012 VMware, Inc. All Rights Reserved.
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

# See how to bring up a MapR cluster on http://www.mapr.com/doc/display/MapR/Bringing+Up+the+Cluster+and+Applying+a+License

if is_mapr_zookeeper
  # Start Zookeeper service
  service node[:mapr][:zookeeper_service_name] do
    action :start
  end
  # Register MapR Zookeeper service provider
  provide_service(node[:mapr][:zookeeper_service_name])
else
  wait_for_zookeeper_nodes
end

## Start MapR Warden service and related services
set_bootstrap_action(ACTION_START_SERVICE, 'mapr-warden', true)
service 'mapr-warden' do
  only_if { File.exist?('/opt/mapr/initscripts/mapr-warden') }
  action :start
end

if is_mapr_cldb
  # some configuration steps require at least 1 node running CLDB service

  grant_perm_to_mapr = '/opt/mapr/bin/maprcli acl edit -type cluster -user mapr:fc'
  params = mysql_connection_params
  configure_metrics_db_conn = %Q{ /opt/mapr/bin/maprcli config save -values "{'jm_db.url': '#{params[:host]}:#{params[:port]}', 'jm_db.user': '#{params[:user]}', 'jm_db.passwd': '#{params[:pwd]}', 'jm_db.schema': '#{params[:schema]}', 'jm_configured': '1'}" }

  execute 'after-mapr-cldb-starts' do
    command %Q{
# Wait 60 seconds for the warden to start the CLDB service.
sleep 60

# If there are more than one CLDB nodes, only one CLDB service will start successfully, 
# and other CLDB services will shutdown because CLDB HA is not enabled until M5 License is applied on MCS.
# Check whether CLDB is running.
source /opt/mapr/conf/env.sh
PATH=$JAVA_HOME/bin:$PATH
jps | grep -q CLDB
[ $? -ne 0 ] && exit

# Give full admin permission to the mapr user.
#{grant_perm_to_mapr}

# Let Metrics DB Configuration take effect in MCS.
# This is a workaround for http://answers.mapr.com/questions/5163/how-to-specify-the-mysql-database-parameters-from-the-command-line
#{configure_metrics_db_conn}

# restart hoststats service
/opt/mapr/bin/maprcli node services -nodes `hostname` -name hoststats -action restart
}
  end
end

clear_bootstrap_action(true)