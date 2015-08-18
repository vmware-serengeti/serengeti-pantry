name             "tempfs"
maintainer       "haiyuwang"
maintainer_email "haiyuwang@vmware.com"
license          ""
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1"

description      "tempfs : temp shared filesystem"
depends          "java"
depends          "cluster_service_discovery"
depends          "hadoop_common"

recipe           "tempfs::client",                        "TempFS client: discovers nfs server, and mounts the corresponding TempFS directory"
recipe           "tempfs::default",                       "TempFS Client: common configuration and package installation"
recipe           "tempfs::server",                        "TempFS server: exports directories via NFS"

%w[ redhat centos debian ubuntu ].each do |os|
  supports os
end
