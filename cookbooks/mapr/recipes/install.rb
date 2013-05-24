#
#   Portions Copyright (c) 2012-2013 VMware, Inc. All Rights Reserved.
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

## Install MapR packages specified by roles
# mapping of role to package. 'true' means this role has a corresponding recipe.
role2pkg = {
  'mapr_zookeeper' => 'mapr-zookeeper',
  'mapr_cldb' => 'mapr-cldb',
  'mapr_fileserver' => 'mapr-fileserver',
  'mapr_nfs' => true,
  'mapr_jobtracker' => 'mapr-jobtracker',
  'mapr_tasktracker' => 'mapr-tasktracker',
  'mapr_webserver' => 'mapr-webserver',
  'mapr_metrics' => 'mapr-metrics',
  'mapr_pig' => 'mapr-pig',
  'mapr_hive' => 'mapr-hive',
  'mapr_hbase_master' => 'mapr-hbase-master',
  'mapr_hbase_regionserver' => 'mapr-hbase-regionserver',
  'mapr_hbase_client' => 'mapr-hbase-internal',
}
role2pkg.each do |role_name, pkg_name|
  if node.role?(role_name)
    set_bootstrap_action(ACTION_INSTALL_PACKAGE, role_name.gsub('_', '-'), true)
    if pkg_name == true
      include_recipe role_name.sub('_', '::')
    else
      package pkg_name
    end
  end
end
clear_bootstrap_action(true)

