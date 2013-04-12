name        'mapr_hbase_regionserver'
description 'MapR HBase Regionserver'

run_list *%w[
  role[mapr]
]
