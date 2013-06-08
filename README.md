# VMware Serengeti Cookbooks and Roles

This repository contains all the cookbooks and roles used in VMware Serengeti Project.

All cookbooks and roles are created/modified by VMware Serengeti Project based on cookbooks and roles open sourced by [Infochimps](https://github.com/infochimps-labs/ironfan-pantry).

To understand the basic concept of Cookbooks and Roles (defined by Chef), please read [Chef Wiki](http://wiki.opscode.com/display/chef/Home) first.

## Main Changes in VMware Serengeti Cookbooks

* Generate user defined hadooop configuration (in cluster/facet roles) in hadoop conf files 
* Add support for deploying a Hadoop cluster using various Hadoop Distributions (e.g. Apache Hadoop 1.x, GreenPlum HD 1.x, Pivotal HD 1.x, Cloudera CDH3 and CDH4(MRv1 and YARN), Hortonworks, MapR etc.).
* The cookbooks are targeted for deploying a Hadoop 0.20 or 1.x cluster with support for HDFS, MapReduce, HBase, Pig and Hive.
* The cookbooks run well on a VM or server with CentOS 5.6+ or CentOS 6.2+ installed. RHEL 5.6+ and 6.2+ should also work but not tested.

Note:
* Hadoop 2.x (i.e. HDFS2 and YARN) is supported via CDH4 and Pivotal HD 1.x.
* To deploy CDH4/MapR/PivotalHD cluster, you need to specify the yum server which contains CDH4/MapR/PivotalHD rpm packages. This is different from deploy Apache Hadoop, Hortonworks and GreenPlum HD cluster.

## Roles

We mainly define the following roles for deploying a Hadoop cluster via Chef.

* hadoop : basic role applied to all nodes in a Hadoop cluster.
* hadoop_namenode    : run Hadoop NameNode service in a cluster node
* hadoop_datanode    : run Hadoop DataNode service in one or more cluster nodes
* hadoop_jobtracker  : run Hadoop JobTracker service in a cluster node
* hadoop_tasktracker : run Hadoop TaskTracker service in one or more cluster nodes
* hadoop_resourcemanager: run Hadoop ResourceManager service in a cluster node
* hadoop_nodemanager : run Hadoop NodeManager service in a cluster node
* hive : install Hive package in a cluster node
* hive_server : install Hive Server in a cluster node and use postgresql as the meta db
* pig  : install Pig package in a cluster node
* hadoop_client : create a node running as a client to submit MapReduce/Pig/Hive jobs to the cluster
* postgresql_server: install a Postgresql Server
* zookeeper: install and run Apache Zookeeper service
* hbase_master: install and run Apache HBase Master service
* hbase_regionserver: install and run Apache HBase RegionServer service
* hbase_client: install Apache HBase package and setup HBase configuration
* mapr_*: install MapR packages

Each role points to recipes contained in several cookbooks.

## Cookbooks and Recipes

We mainly create the following cookbooks and recipes for deploying a Hadoop cluster via Chef.

* cluster_service_discovery : runtime Hadoop services discovery (e.g. tell all nodes in a cluster what's the ip of the Hadoop NameNode)
* hadoop_cluster : contain following recipes for installing Hadoop package and running Hadoop services
   * namenode
   * datanode
   * jobtracker
   * tasktracker
   * resourcemanager
   * nodemanager
   * etc.
* pig  : install Pig package
* hive : install Hive package
* hbase : install HBase package
* zookeeper : install Zookeeper package
* mapr: install MapR package
* postgresql : install a Postgresql Server
* install_from : install a package from a tarball

## New Features

### Support for Multi Hadoop Distributions

The support for Multi Hadoop Distribution is a big exciting feature we add into VMware Serengeti Cookbooks.

In order to support multi Hadoop distributions, we choose to install Hadoop/Pig/Hive packages from the tarball
provided by Hadoop distributors. Because the folder structure of Hadoop binary tarballs and the way to start 
the Hadoop NameNode/JobTracker/DataNode/TaskTracker service in various Hadoop distributions are almost the same,
we can easily support various Hadoop distributions with minimum changes.

#### Specify a Hadoop Distribution to Deploy

The meta data of a Hadoop distribution is saved into Chef databag 'hadoop_distros' before running the cookbooks.
Here is an example of databag containing the meta data of Apache Hadoop distribution:
<pre>
  $ knife data bag show hadoop_distros apache
  id:      apache  (the name of this Hadoop distribution)
  hadoop:  http://localhost/distros/apache/1.0.1/hadoop-1.0.1.tar.gz  (the url of hadoop tarball of this Hadoop distribution)
  hive:    http://localhost/distros/apache/1.0.1/hive-0.8.1.tar.gz    (the url of hive tarball of this Hadoop distribution)
  pig:     http://localhost/distros/apache/1.0.1/pig-0.9.2.tar.gz     (the url of pig tarball of this Hadoop distribution)
  hbase:   http://localhost/distros/apache/1.0.1/hbase-0.94.0.tar.gz  (the url of hbase tarball of this Hadoop distribution)
  zookeeper: http://localhost/distros/apache/1.0.1/zookeeper-3.4.3.tar.gz  (the url of zookeeper tarball of this Hadoop distribution)
</pre>
You can manually save meta data for a new Hadoop Distribution with id 'new_distro' into the databag 'hadoop_distros',
add the following code in cluster role file, and upload the cluster role to Chef Server, then bootstrap the node.
<pre>
  override_attributes({
    :hadoop => {
      :distro_name => "new_distro"
    }
  })
</pre>
When VMware Serengeti Cookbooks is used by VMware Serengeti Ironfan to deploy a Hadoop cluster, the meta data of a Hadoop distribution is
specified in cluster definition file. Ironfan will read the meta data and save to databags automatically. Please read VMware Serengeti Ironfan
user guide to find out how to use it.

#### Tested Hadoop Distributions
We have tested that VMware Serengeti Cookbooks can be used to successfully deploy a Hadoop cluster with the following Hadoop distributions:

* [Apache Hadoop 1.x and 1.2](http://newverhost.com/pub/hadoop/common/hadoop-1.2.0/), [Apache Pig 0.9.2](http://www.us.apache.org/dist/pig/pig-0.9.2/), [Apache Hive 0.8.1](http://www.us.apache.org/dist/hive/hive-0.8.1/), [Apache HBase 0.94.0](http://www.us.apache.org/dist/hbase/), and [Apache Zookeeper 3.4.3](http://www.us.apache.org/dist/zookeeper/zookeeper-3.4.3/)
* [GreenPlum HD 1.x](http://www.greenplum.com/products/greenplum-hd) which includes Hadoop 1.0.0, Hive 0.7.1 and Pig 0.9.1
* [Cloudera CDH3u6](http://archive.cloudera.com/cdh/3/hadoop-0.20.2-cdh3u3/) which includes Hadoop 0.20.2, Hive 0.7.1 and Pig 0.8.1
* [Cloudear CDH4.1.x and CDH4.2.x](http://archive.cloudera.com/cdh4/redhat/5/x86_64/cdh/4/) which includes Hadoop 2.0.0, Hive 0.10.0 and Pig 0.11.0
* [Hortonworks HDP 1.x and 2.x](http://s3.amazonaws.com/public-repo-1.hortonworks.com/HDP-1.2.0/repos/centos5/HDP-1.2.0-centos5.tar.gz)
* [Pivotal HD 1.0](http://pivotallabs.com/)
* [MapR 2.1.x](http://package.mapr.com/releases/)

Other Hadoop 0.20 or 1.x series distributions should also work well but not tested.
Please let us know if other Hadoop/Pig/Hive combination works in your environment.

### Support for User Specified Hadoop Configuration
A Hadoop admin may want to tune the hadoop cluster configuration by modifying configuration attributes in core-site.xml, hdfs-site.xml, mapred-site.xml, hadoop-env.sh, etc.
In Ironfan, the Hadoop admin can add the following code in cluster role file, and upload the cluster role to Chef Server, then bootstrap the node, and all specified configuration will apply to the whole cluster. If add the following code in facet role file, the specified configuration will only apply to that facet.
<pre>
  default_attributes({
    "cluster_configuration": {
      "hadoop": {
        "core-site.xml": {
          // check for all settings at http://hadoop.apache.org/common/docs/r1.0.0/core-default.html
          // note: any value (int, float, boolean, string) must be enclosed in double quotes and here is a sample:
          // "io.file.buffer.size": "4096"
        },
        "hdfs-site.xml": {
          // check for all settings at http://hadoop.apache.org/common/docs/r1.0.0/hdfs-default.html
          // "dfs.replication": "3"
        },
        "mapred-site.xml": {
          // check for all settings at http://hadoop.apache.org/common/docs/r1.0.0/mapred-default.html
          // "mapred.map.tasks": "3"
        },
        "hadoop-env.sh": {
          // "JAVA_HOME": "",
          // "HADOOP_HEAPSIZE": "",
          // "HADOOP_NAMENODE_OPTS": "",
          // "HADOOP_DATANODE_OPTS": "",
          // "HADOOP_SECONDARYNAMENODE_OPTS": "",
          // "HADOOP_JOBTRACKER_OPTS": "",
          // "HADOOP_TASKTRACKER_OPTS": "",
          // "PATH": ""
        },
        "log4j.properties": {
          // "hadoop.root.logger": "DEBUG,DRFA",
          // "hadoop.security.logger": "DEBUG,DRFA"
        }
      }
    }
  })
</pre>

# Contact
Please send email to our mailing lists for [developers](https://groups.google.com/group/serengeti-dev) or for [users](https://groups.google.com/group/serengeti-user) if you have any questions.

# Notice
Copyright (c) 2012-2013 VMware, Inc. All Rights Reserved.

This product is licensed to you under the Apache License, Version 2.0 (the "License").  
You may not use this product except in compliance with the License.  

This product may include a number of subcomponents with
separate copyright notices and license terms. Your use of the source
code for the these subcomponents is subject to the terms and
conditions of the subcomponent's license, as noted in the LICENSE file. 

