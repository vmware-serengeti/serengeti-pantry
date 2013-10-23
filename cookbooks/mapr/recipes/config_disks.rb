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

# should format disks on the mapr-fileserver node only
return if !node.role?('mapr_fileserver')
# disks info must exist
if !node[:disk]
  Chef::Log.info("No data disk is attached to this VM.")
  return
end

mount_swap_disk(node[:disk][:swap_disk])

## format local disk for MapR
disk_file = '/opt/mapr/conf/disks.txt'
if !File.exists?(disk_file)
  disks = node[:disk][:disk_devices].values.collect{ |disk| disk if File.exists?(disk) }
  disk_string = disks.join(',')
  file disk_file do
    owner "mapr"
    group "mapr"
    content disk_string.gsub("," , "\n") + "\n"
  end

  set_bootstrap_action(ACTION_FORMAT_DISK, '', true)
  bash "format disks for MapR" do
    user "root"
    code "/opt/mapr/server/disksetup -F -M #{disk_file}"
  end
  clear_bootstrap_action
end
