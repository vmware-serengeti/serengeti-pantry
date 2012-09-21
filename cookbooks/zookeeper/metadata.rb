maintainer       "VMware Inc."
maintainer_email "bchang@vmware.com"
license          "Apache 2.0"
description      "Installs/Configures zookeeper"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version          "0.1.0"

description      "Installs/Configures zookeeper using official apache tar.gz. package"

depends          "java"
depends          "install_from"
depends          "cluster_service_discovery"
depends          "hadoop_common"

recipe "zookeeper::default", "Install/Configures zookeeper"

%w{ redhat centos debian ubuntu }.each do |os|
  supports os
end
