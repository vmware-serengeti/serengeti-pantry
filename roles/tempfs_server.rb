name        'tempfs_server'
description 'A role for running tempfs service'

run_list *%w[
	tempfs::server
]
