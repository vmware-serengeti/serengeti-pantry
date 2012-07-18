name        'hive_server'
description 'A role for running Apache Hive server service'

run_list *%w[
  role[hive]
  role[postgresql_server]
  hive::server
]
