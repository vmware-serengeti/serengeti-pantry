## Config local disks for hadoop
# { mount_point => device }  e.g. '/mnt/sdb1' => '/dev/sdb1'
default[:disk][:data_disks] = {}
# { device => disk }  e.g. '/dev/sdb1' => '/dev/sdb'
default[:disk][:disk_devices] = {}
