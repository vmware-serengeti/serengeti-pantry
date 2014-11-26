name        'mesos_docker'
description 'Deploy the docker executor on Apache Mesos slave node.'

run_list *%w[
  role[basic]
]

