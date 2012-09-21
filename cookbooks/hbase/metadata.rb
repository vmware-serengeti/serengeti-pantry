maintainer       "VMware Inc."
maintainer_email "bchang@vmware.com"
license          "Apache License 2.0"
description      "Install/Configure HBase"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.1.0"

depends          "java"
depends          "install_from"
depends          "cluster_service_discovery"
depends          "hadoop_cluster"

recipe "hbase::default", "Install hbase package"
recipe "hbase::master", "Install hbase HMaster"
recipe "hbase::regionserver", "Install hbase RegionServer"
recipe "hbase::client", "Install hbase client"

%w{ redhat centos debian ubuntu }.each do |os|
  supports os
end
