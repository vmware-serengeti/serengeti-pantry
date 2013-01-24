name        'mapr_fileserver'
description 'MapR fileserver'

run_list *%w[
  role[mapr]
]
