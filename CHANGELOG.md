# 0.8.0 (2013-2-21)

New Features:
* Add cookbooks and roles for deploying CDH4(MR1) cluster w/ or w/o HDFS HA and HDFS Federation
* Add cookbooks and roles for deploying MapR cluster.
* Some enhancement and bug fix.

# 0.7.0 (2012-10-8)

New Features:
* Add Zookeeper and HBase cookbooks/roles for deploying a Zookeeper or HBase cluster
* Enhance service register framework to ensure service is registered after the service daemon is started and ready to handle requests. This can eliminate intermittent synchronization issue between dependent service daemons
* Add support for tuning fair-scheduler.xml, capacity-scheduler.xml and mapred-queue-acls.xml
* Add ulimit settings in hadoop-daemon.sh
* Auto detect JAVA_HOME from /etc/profile instead of hardcode.
* Enable configuration for Hadoop Topology Rack Awareness and Hadoop Virtualization Extensions

Bug Fix:
* When bootstrapping, either service start or service restart should be triggerred, but not both, because restart after start is unnecessary.
* For hadoop daemons: set HADOOP_ROOT_LOGGER to hadoop.root.logger value in log4j.properties.
* Fix issue: hadoop services restart returns zero instead of non-zero when restart failed.

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
