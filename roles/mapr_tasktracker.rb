name        'mapr_tasktracker'
description 'MapR tasktracker'

run_list *%w[
  role[mapr]
]
