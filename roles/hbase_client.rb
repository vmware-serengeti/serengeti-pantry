name        'hbase_client'
description 'A role for running Apache HBase client'

run_list *%w[
  hbase::client
]
