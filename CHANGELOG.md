# 0.6.0 (2012-8-21)

New Features:
* Support for User Specified Hadoop Configuration
* Generate user specified yum repo file in /etc/yum.repo.d/
* Enable WebHDFS REST API by default
* Add cookbook/role for postgresql_server and hive_server

Bug Fix:

* Fix issue: hadoop services restart returns zero instead of non-zero when restart failed
* Make log4j.properties work for hadoop 0.20, 0.23 and 1.x
* Restart hadoop services only when related configuration files are changed

# 0.5.0 (2012-6-13)

* Initial import for Serengeti 0.5.0
* Contains cookbooks and roles for hadoop 0.20.x, hive, pig, etc.
