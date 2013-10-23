maintainer        "VMware Inc."
maintainer_email  "serengeti-dev@googlegroups.com"
license           "Apache 2.0"
description       "Installs hadoop and sets up a high-performance cluster. Inspired by Tom White / Cloudera's hadoop-ec2 command line utilities"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.rdoc'))
version           "1.3.0"
depends           "java"
depends           "hadoop_common"
depends           "zookeeper"
depends           "cluster_service_discovery"

%w{ debian ubuntu }.each do |os|
  supports os
end
