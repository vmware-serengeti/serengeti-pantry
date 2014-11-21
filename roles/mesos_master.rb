name        'mesos_master'
description 'Deploy the Apache Mesos master node.'

run_list *%w[
  role[basic]
  mesos::master
]

