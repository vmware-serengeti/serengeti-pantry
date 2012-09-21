name        'zookeeper'
description 'A role for running Apache zookeeper server'

run_list *%w[
  zookeeper
]
