name        'pig'
description 'A role for running Apache Pig service'

run_list *%w[
  role[hadoop]
  pig
]
