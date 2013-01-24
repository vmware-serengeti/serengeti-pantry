name        'mapr_webserver'
description 'MapR webserver'

run_list *%w[
  role[mapr]
]
