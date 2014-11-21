name        'kubernetes_master'
description 'Deploy the Kubernetes master node.'

run_list *%w[
  role[basic]
  kubernetes::master
]

