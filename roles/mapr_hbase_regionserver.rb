name        'mapr_hbase_regionserver'
description 'MapR HBase RegionServer'

run_list *%w[
  role[mapr]
]
