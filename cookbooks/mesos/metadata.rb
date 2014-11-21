name 'mesos'
maintainer 'Medidata Solutions'
maintainer_email 'hwilkinson@mdsol.com'
license 'Apache 2.0'
description 'Installs/Configures Apache Mesos'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version '2.1.0'

%w( ubuntu centos amazon scientific ).each do |os|
  supports os
end

depends 'cluster_service_discovery'
depends 'zookeeper'
