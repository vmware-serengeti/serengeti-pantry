name        'hive'
description 'A role for running Apache Hive service'

run_list *%w[
  hive
]
