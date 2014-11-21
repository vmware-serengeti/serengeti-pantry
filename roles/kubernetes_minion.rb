name        'kubernetes_minion'
description 'Deploy the Kubernetes minion node.'

run_list *%w[
  role[basic]
  kubernetes::minion
]

