name        'mapr_jobtracker'
description 'MapR jobtracker'

run_list *%w[
  role[mapr]
]
