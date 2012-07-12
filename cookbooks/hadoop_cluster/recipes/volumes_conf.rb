#
# Cookbook Name:: hadoop_cluster
# Recipe::        volumes_conf
#

#
# Portions Copyright (c) 2012 VMware, Inc. All Rights Reserved.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

#
# Format attached disk devices
#
node[:disk][:disk_devices].each do |dev, disk|
  execute "formatting disk device #{disk}" do
    only_if do File.exist?(disk) end
    not_if do File.exist?(dev) end
    command %Q{
      flag=1
      while [ $flag -ne 0 ] ; do
        echo 'Running: sfdisk -uM #{disk}. Occasionally it will fail, we will re-run.'
        echo ",,L" | sfdisk -uM #{disk}
        flag=$?
        sleep 3
      done

      echo "y" | mkfs #{dev}
    }
  end
end

#
# Mount big ephemeral drives, make hadoop dirs on them
#
node[:disk][:data_disks].each do |mount_point, dev|
  next unless File.exists?(node[:disk][:disk_devices][dev])

  Chef::Log.info "mounting data disk #{dev} at #{mount_point} if not mounted"
  directory mount_point do
    only_if{ File.exists?(dev) }
    owner     'root'
    group     'root'
    mode      '0755'
    action    :create
  end

  dev_fstype = fstype_from_file_magic(dev)
  mount mount_point do
    only_if{ dev && dev_fstype }
    only_if{ File.exists?(dev) }
    device dev
    fstype dev_fstype
  end

  # Chef Resource mount doesn't enable automatically mount disks when OS starts up. We add it here.
  mount_device_command = "#{dev}\t\t#{mount_point}\t\t#{dev_fstype}\tdefaults\t0 0"
  execute 'add mount info into /etc/fstab if not added' do
    command %Q{
      grep "#{dev}" /etc/mtab > /dev/null
      if [ $? == 0 ]; then
        grep "#{dev}" /etc/fstab > /dev/null
        if [ $? == 1 ]; then
          echo "#{mount_device_command}" >> /etc/fstab
        fi
      fi
    }
  end

end

# Directory /mnt/hadoop is used across this cookbook
make_hadoop_dir '/mnt/hadoop', 'hdfs'

local_hadoop_dirs.each do |dir|
  make_hadoop_dir dir, 'hdfs'
end

# Important: In CDH3 Beta 3, the mapred.system.dir directory must be located inside a directory that is owned by mapred. For example, if mapred.system.dir is specified as /mapred/system, then /mapred must be owned by mapred. Don't, for example, specify /mrsystem as mapred.system.dir because you don't want / owned by mapred.
#
# Directory             Owner           Permissions
# dfs.name.dir          hdfs:hadoop     drwx------
# dfs.data.dir          hdfs:hadoop     drwxr-xr-x
# mapred.local.dir      mapred:hadoop   drwxr-xr-x
# mapred.system.dir     mapred:hadoop   drwxr-xr-x

#
# Physical directories for HDFS files and metadata
#
dfs_name_dirs.each{      |dir| make_hadoop_dir(dir, 'hdfs',   "0700") }
dfs_data_dirs.each{      |dir| make_hadoop_dir(dir, 'hdfs',   "0755") }
fs_checkpoint_dirs.each{ |dir| make_hadoop_dir(dir, 'hdfs',   "0700") }
mapred_local_dirs.each{  |dir| make_hadoop_dir(dir, 'mapred', "0755") }

