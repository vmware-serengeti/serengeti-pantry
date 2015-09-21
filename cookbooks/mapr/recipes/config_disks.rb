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

# should format disks on the mapr-fileserver node only
return if !node.role?('mapr_fileserver')
# disks info must exist
if !node[:disk]
  Chef::Log.info("No data disk is attached to this VM.")
  return
end

## format local disk for MapR
disk_file = '/opt/mapr/conf/disks.txt'
disks = node[:disk][:disk_devices].values.collect{ |disk| disk if File.exists?(disk) }

new_disks = []
old_disks = []

if File.exists?(disk_file)
  # get new disks if there are failed disks in MapR cluster
  old_disks = File.read(disk_file).split("\n")
  disks.each do | disk |
    new_disks << disk unless old_disks.include?(disk)
  end
else
  new_disks = disks
end

if new_disks.any?
  Chef::Log.info "new disks: #{new_disks.to_s}"

  new_disks_file = '/opt/mapr/conf/new_disks.txt'
  new_disks_string = new_disks.join(',')

  file new_disks_file do
    owner "mapr"
    group "mapr"
    content new_disks_string.gsub("," , "\n") + "\n"
  end

  set_bootstrap_action(ACTION_FORMAT_DISK, '', true)
  bash "format new disks for MapR" do
    user "root"
    code "/opt/mapr/server/disksetup -F -M #{new_disks_file}"
    retries 10
    retry_delay 3
  end

  file new_disks_file do
    owner "mapr"
    group "mapr"
    action :delete
  end

  # Update all data disks to disks.txt
  disk_string = disks.join(',')
  file disk_file do
    owner "mapr"
    group "mapr"
    content disk_string.gsub("," , "\n") + "\n"
  end

  clear_bootstrap_action
end
