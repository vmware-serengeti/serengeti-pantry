name        'hbase_master'
description 'A role for running Apache HBase Master'

run_list *%w[
  hbase::master
]
