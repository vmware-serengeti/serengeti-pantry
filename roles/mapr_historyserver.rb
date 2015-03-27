name        'mapr_historyserver'
description 'MapR YARN History Server'

run_list *%w[
  role[mapr]
]
