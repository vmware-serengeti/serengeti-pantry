name        'mapr_client'
description 'MapR client'

run_list *%w[
  role[mapr]
]
