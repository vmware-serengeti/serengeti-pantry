overcommit_memory  =     1
overcommit_ratio   =   100
ulimit_hard_nofile = 32768
ulimit_soft_nofile = 32768
ulimit_hard_nproc = 32000
ulimit_soft_nproc = 32000

def set_proc_sys_limit desc, proc_path, limit
  bash desc do
    not_if{ File.exists?(proc_path) && (File.read(proc_path).chomp.strip == limit.to_s) }
    code  "echo #{limit} > #{proc_path}"
  end
end

set_proc_sys_limit "VM overcommit ratio", '/proc/sys/vm/overcommit_memory', overcommit_memory
set_proc_sys_limit "VM overcommit memory", '/proc/sys/vm/overcommit_ratio',  overcommit_ratio

bash "Increase nofile and noproc for hadoop-daemon.sh" do
  not_if "egrep -q '^ulimit' /usr/lib/hadoop/bin/hadoop-daemon.sh"
  code <<EOF
    sed -i '/^pid=/ a\\ulimit -n 32768' /usr/lib/hadoop/bin/hadoop-daemon.sh
    sed -i '/^pid=/ a\\ulimit -u 32000' /usr/lib/hadoop/bin/hadoop-daemon.sh
    sed -i '/^pid=/ a\# set nproc and nofile' /usr/lib/hadoop/bin/hadoop-daemon.sh
    sed -i '/^pid=/G' /usr/lib/hadoop/bin/hadoop-daemon.sh
EOF
end

%w[ @hadoop ].each do |usr|
  { 'hard' => ulimit_hard_nofile, 'soft' => ulimit_soft_nofile,  }.each do |limit_type, limit|
    bash "Increase open files #{limit_type} ulimit for #{usr} group" do
      not_if "egrep -q '#{usr}.*#{limit_type}.*nofile.*#{limit}' /etc/security/limits.conf"
      code <<EOF
        egrep -q '#{usr}.*#{limit_type}.*nofile' || ( echo '#{usr} #{limit_type} nofile' >> /etc/security/limits.conf )
        sed -i "s/#{usr}.*#{limit_type}.*nofile.*/#{usr}    #{limit_type}    nofile  #{limit}/" /etc/security/limits.conf
EOF
    end
  end
end

%w[ @hadoop ].each do |usr|
  { 'hard' => ulimit_hard_nproc, 'soft' => ulimit_soft_nproc,  }.each do |limit_type, limit|
    bash "Increase maximum number of processes #{limit_type} ulimit for #{usr} group" do
      not_if "egrep -q '#{usr}.*#{limit_type}.*nproc.*#{limit}' /etc/security/limits.conf"
      code <<EOF
        egrep -q '#{usr}.*#{limit_type}.*nproc' || ( echo '#{usr} #{limit_type} nproc' >> /etc/security/limits.conf )
        sed -i "s/#{usr}.*#{limit_type}.*nproc.*/#{usr}    #{limit_type}  nproc  #{limit}/" /etc/security/limits.conf
EOF
    end
  end
end
