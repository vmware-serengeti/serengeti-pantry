name        'mapr_hbase_client'
description 'MapR HBase Client'

run_list *%w[
  role[mapr]
]
