name        'postgresql_server'
description 'A role for running Postgresql service'

run_list *%w[
  postgresql::server
]
