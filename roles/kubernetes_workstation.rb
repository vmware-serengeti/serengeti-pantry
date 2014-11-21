name        'kubernetes_workstation'
description 'Deploy the Kubernetes Workstation.'

run_list *%w[
  role[basic]
  kubernetes::workstation
]

