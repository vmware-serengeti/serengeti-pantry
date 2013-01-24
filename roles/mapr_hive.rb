name        'mapr_hive'
description 'MapR Hive'

run_list *%w[
  role[mapr]
]
