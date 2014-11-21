name        'mesos_slave'
description 'Deploy the Apache Mesos slave node.'

run_list *%w[
  role[basic]
  mesos::slave
]

