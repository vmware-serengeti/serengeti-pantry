name             'kubernetes'
maintainer       'Jesse Hu'
maintainer_email 'huh@vmware.com'
license          'Apache License Version 2'
description      'Installs/Configures kubernetes cluster'
long_description IO.read(File.join(File.dirname(__FILE__), 'README.md'))
version          '0.2.0'
depends          'cluster_service_discovery'
depends          "install_from"
