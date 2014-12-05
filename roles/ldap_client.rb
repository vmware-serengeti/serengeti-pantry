name        'ldap_client'
description 'Configure the node to connect to a LDAP server'

run_list *%w[
  sssd_ldap
]
