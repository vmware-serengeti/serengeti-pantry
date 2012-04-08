maintainer       "Hui Hu"
maintainer_email "huh@vmware.com"
license          "Apache License, Version 2.0"
description      "Install/Configure Apache HBase"
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          "0.1.0"

depends 'java'
depends 'hadoop_cluster'
depends 'cluster_service_discovery'