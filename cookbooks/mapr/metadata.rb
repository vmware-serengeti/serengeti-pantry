name              "mapr"
maintainer        "VMware Inc."
maintainer_email  "serengeti-dev@googlegroups.com"
license           "Apache 2.0"
description       "MapR cookbook"
long_description  IO.read(File.join(File.dirname(__FILE__), 'README.txt'))
version           "0.2.0"

depends           "hadoop_common"
depends           "cluster_service_discovery"
depends           "mysql"

%w[ centos redhat ].each do |os|
  supports os
end
