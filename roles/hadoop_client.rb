name        'hadoop_client'
description 'A role for creatting a hadoop client'

run_list *%w[
  role[hadoop]
]
