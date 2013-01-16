name        'tempfs_client'
description 'A role for running tempfs client'

run_list *%w[
	tempfs::client
]
