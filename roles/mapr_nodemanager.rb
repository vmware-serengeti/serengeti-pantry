name        'mapr_nodemanager'
description 'MapR YARN Node Manager'

run_list *%w[
  role[mapr]
]
