name        'mesos_marathon'
description 'Deploy Marathon on Apache Mesos.'

run_list *%w[
  role[basic]
]
