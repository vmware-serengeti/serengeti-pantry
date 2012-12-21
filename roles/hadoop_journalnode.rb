name 'hadoop_journalnode'
description 'runs a journalnode in fully-distributed mode. There should be exactly one of these per cluster.'

run_list %w[
  role[hadoop]
  hadoop_cluster::journalnode
]
