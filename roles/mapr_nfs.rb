name        'mapr_nfs'
description 'MapR nfs'

run_list *%w[
  role[mapr]
]
