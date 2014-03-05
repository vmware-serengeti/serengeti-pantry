name        'basic'
description 'Basic role for any software deployment. It includes seting up IP/FQDN, mounting and formatting local disks.'

run_list *%w[
  hadoop_common::pre_run
  hadoop_common::mount_disks
]

