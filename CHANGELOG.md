# 2.2.0 (2015-5-8)

Enhancement:
* Use postgresql 9.4 for Hive
* Support for Hadoop 2.x in MapR 4.0

# 2.1.1 (2014-11-27)

New features:
* Add roles and cookbooks for Mesos and Kubernetes

# 2.1.0 (2014-9-15)

New features:
* Add support for configuration of topology.data
* Add support for configuring Namenode address for HBase Only Cluster
* Add support for configuring Jobtracker or ResourceManager address for Tasktracker/NodeManager Only Cluster

Enhancement:
* Set Namenode listening port to default port 8020
* Each HBase cluster has different hbase.rootdir
* Add retry for installing rpms which have big file size
* Other bug fix

# 2.0.0 (2014-4-1)

New features:
* Add support for deploying Hortonworks and Apache Bigtop distro via yum
* Add support for deploying Intel 3.x and other Bigtop based Hadop 2.x distro
* Add Chef Error Reporting Handler to save chef-client exception to Chef Nodes

Enhancement:
* Make some check on the role order due to role depencendies
* Other bug fix

# 1.1.0 (2013-11-11)

New features:
* Upgrade to Chef Client 11
* Enable SSL certificate validation between Chef Server and Chef nodes
* Add support for Intel Hadoop
* Add support for Fedora and Oracle Linux
* Add Support for Multi Network on Hadoop Nodes

Enhancement:
* Use Chef 11 Partial Search API to reduce memory consumption and response time when doing cluster service discovery
* Other bug fix

# 1.0.0 (2013-8-2)

Enhancement:
* Use non root account to start hadoop service
* Format all attached data disks in parallel instead of one by one to speed up bootstrap
* Reduce unneccessary Chef Search API calls when registering a service to support large scale cluster provision (200+ nodes)
* Other bug fix

# 0.9.0 (2013-6-8)

New Features:
* Add support for deploying CDH4 Hadoop/YARN/HBase cluster
* Add support for deploying Pivotal HD Hadoop/YARN/HBase cluster
* Add support for deploying MapR HBase cluster
* Add support for deploying on CentOS 6 in addition to CentOS 5

Serveral bug fixes.

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
