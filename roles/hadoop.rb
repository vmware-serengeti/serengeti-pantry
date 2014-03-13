name        'hadoop'
description 'applies to all nodes in the hadoop cluster'

run_list *%w[
  hadoop_cluster
]

default_attributes({
    # Must use sun java with hadoop
    :java => {
      :install_flavor => 'sun'
    },
  })
