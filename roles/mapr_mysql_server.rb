name        'mapr_mysql_server'
description 'A role for running Mysql service'

run_list *%w[
  mapr::mysql_server
]
