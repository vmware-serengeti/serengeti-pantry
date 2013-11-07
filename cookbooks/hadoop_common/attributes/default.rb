## Config local disks for hadoop
# { mount_point => device }  e.g. '/mnt/sdb1' => '/dev/sdb1'
default[:disk][:data_disks] = {}
# { device => disk }  e.g. '/dev/sdb1' => '/dev/sdb'
default[:disk][:disk_devices] = {}

# SSL settings for Chef Server and Web Server
default[:ssl_ca_path] = '/etc/chef/trusted_certs'
default[:ssl_ca_file_serengeti_httpd] = "#{default[:ssl_ca_path]}/serengeti-base.pem"
