name        'mapr'
description 'MapR default role'

run_list *%w[
  recipe[mapr::prereqs]
  recipe[mapr::install]
  recipe[mapr::config]
  recipe[mapr::startup]
]
