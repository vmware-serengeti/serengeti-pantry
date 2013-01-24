name        'mapr_cldb'
description 'MapR cldb'

run_list *%w[
  role[mapr]
]
