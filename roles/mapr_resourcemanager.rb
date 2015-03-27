name        'mapr_resourcemanager'
description 'MapR YARN Resource Manager'

run_list *%w[
  role[mapr]
]
