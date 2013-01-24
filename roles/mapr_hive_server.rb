name        'mapr_hive_server'
description 'MapR Hive Server'

run_list *%w[
  role[mapr]
]
