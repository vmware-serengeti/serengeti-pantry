#
# Make sure hadoop is the owner of all files in the special hadoop dirs.
#
dfs_name_dirs.each{      |dir| ensure_hadoop_owns_hadoop_dirs(dir, 302, "0700") }
dfs_data_dirs.each{      |dir| ensure_hadoop_owns_hadoop_dirs(dir, 302, "0755") }
fs_checkpoint_dirs.each{ |dir| ensure_hadoop_owns_hadoop_dirs(dir, 302, "0700") }
mapred_local_dirs.each{  |dir| ensure_hadoop_owns_hadoop_dirs(dir, 303, "0755") }
yarn_local_dirs.each{ |dir| ensure_yarn_dirs_stat(dir, "0755")} if is_hadoop_yarn?
yarn_log_dirs.each{ |dir| ensure_yarn_dirs_stat(dir, "0755")} if is_hadoop_yarn?
ensure_hadoop_owns_hadoop_dirs(real_hadoop_log_dir, 302, "0775")
