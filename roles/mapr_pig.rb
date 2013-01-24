name        'mapr_pig'
description 'MapR Pig'

run_list *%w[
  role[mapr]
]
