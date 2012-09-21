name        'hbase_regionserver'
description 'A role for running Apache HBase Regionserver'

run_list *%w[
  hbase::regionserver
]
