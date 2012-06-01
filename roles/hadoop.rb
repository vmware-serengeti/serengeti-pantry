name        'hadoop'
description 'applies to all nodes in the hadoop cluster'

run_list *%w[
  hadoop_cluster
  hadoop_cluster::cluster_conf
  hadoop_cluster::volumes_conf

  hadoop_cluster::hadoop_dir_perms
  hadoop_cluster::dedicated_server_tuning
  ]

default_attributes({
    # Must use sun java with hadoop
    :java => {
      :install_flavor => 'sun'
    },
  })
