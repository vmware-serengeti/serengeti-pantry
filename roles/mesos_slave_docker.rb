name        'mesos_slave_docker'
description 'Deploy the Apache Mesos slave node running the docker executor.'

run_list *%w[
  role[basic]
  mesos::docker
]

