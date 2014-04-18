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

# Format DFSZKFailoverController
execute 'format ZK' do
  not_if "service #{node[:hadoop][:zkfc_service_name]} status"
  not_if { File.exists?('/mnt/hadoop/.zk_formatted.log') }
  user 'hdfs'
  command %Q{
    yes 'Y' | #{node[:hadoop][:hadoop_hdfs_dir]}/bin/hdfs zkfc -formatZK
    exit_status=$?
    if [ $exit_status -eq 0 ]; then touch /mnt/hadoop/.zk_formatted.log ; fi
    exit $exit_status
  }
end

# Notify primary zkfc format
notify(node[:hadoop][:primary_zkfc_format])
