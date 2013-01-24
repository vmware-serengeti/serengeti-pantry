name        'mapr_zookeeper'
description 'MapR zookeeper'

run_list *%w[
  role[mapr]
]
