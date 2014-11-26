name        'mesos_chronos'
description 'Deploy Chronos on Apache Mesos.'

run_list *%w[
  role[basic]
]

