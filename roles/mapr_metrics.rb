name        'mapr_metrics'
description 'MapR metrics'

run_list *%w[
  role[mapr]
]
