module HadoopCluster

  # The namenode's hostname, or the local node's numeric ip if 'localhost' is given.
  def namenode_address
    provider_private_ip("#{node[:cluster_name]}-#{node[:hadoop][:namenode_service_name]}")
  end

  def namenode_port
    node[:hadoop][:namenode_service_port]
  end

  # The resourcemanager's hostname, or the local node's numeric ip if 'localhost' is given.
  # The resourcemanager in hadoop-0.23 is vary similar to the jobtracker in hadoop-0.20.
  def resourcemanager_address
    provider_private_ip("#{node[:cluster_name]}-#{node[:hadoop][:resourcemanager_service_name]}")
  end
  
  # The jobtracker's hostname, or the local node's numeric ip if 'localhost' is given.
  def jobtracker_address
    provider_private_ip("#{node[:cluster_name]}-#{node[:hadoop][:jobtracker_service_name]}")
  end

  # The erb template variables for generating Hadoop xml configuration files in $HADDOP_HOME/conf/
  def hadoop_template_variables
    {
      :hadoop_home            => hadoop_home_dir,
      :namenode_address       => namenode_address,
      :namenode_port          => namenode_port,
      :resourcemanager_address => resourcemanager_address,
      :jobtracker_address     => jobtracker_address,
      :mapred_local_dirs      => formalize_dirs(mapred_local_dirs),
      :dfs_name_dirs          => formalize_dirs(dfs_name_dirs),
      :dfs_data_dirs          => formalize_dirs(dfs_data_dirs),
      :fs_checkpoint_dirs     => formalize_dirs(fs_checkpoint_dirs),
      :local_hadoop_dirs      => formalize_dirs(local_hadoop_dirs),
      :persistent_hadoop_dirs => formalize_dirs(persistent_hadoop_dirs),
      :all_cluster_volumes    => all_cluster_volumes,
    }
  end

  def hadoop_package component
    hadoop_major_version = node[:hadoop][:hadoop_handle]
    package_name = "#{hadoop_major_version}#{component ? '-' : ''}#{component}"
    hadoop_home = hadoop_home_dir

    # Install from tarball
    if node[:hadoop][:install_from_tarball] then
      tarball_url = current_distro['hadoop']
      tarball_filename = tarball_url.split('/').last
      tarball_pkgname = tarball_filename.split('.tar.gz').first
      Chef::Log.info "start installing package #{tarball_pkgname} from tarball"

      if component == nil then
        # install hadoop base package
        install_dir = [File.dirname(hadoop_home), tarball_pkgname].join('/')
        already_installed = File.exists?(install_dir)
        if already_installed then
          Chef::Log.info("#{tarball_filename} has already been installed. Will not re-install.")
          return
        end

        set_bootstrap_action(ACTION_INSTALL_PACKAGE, package_name)

        execute "install #{tarball_pkgname} from tarball if not installed" do
          not_if do already_installed end

          command %Q{
            if [ ! -f /usr/local/src/#{tarball_filename} ]; then
              echo 'downloading tarball #{tarball_filename}'
              cd /usr/local/src/
              wget #{tarball_url}
            fi

            echo 'extract the tarball'
            prefix_dir=`dirname #{hadoop_home}`
            install_dir=$prefix_dir/#{tarball_pkgname}
            mkdir -p $install_dir
            cd $install_dir
            tar xzf /usr/local/src/#{tarball_filename} --strip-components=1
            chown -R hdfs:hadoop $install_dir

            echo 'create symbolic links'
            ln -sf -T $install_dir $prefix_dir/#{hadoop_major_version}
            ln -sf -T $install_dir #{hadoop_home}
            mkdir -p /etc/#{hadoop_major_version}
            ln -sf -T #{hadoop_home}/conf  /etc/#{hadoop_major_version}/conf
            ln -sf -T /etc/#{hadoop_major_version} /etc/hadoop

            # create hadoop logs directory, otherwise created by root:root with 755
            mkdir             #{hadoop_home}/logs
            chmod 777         #{hadoop_home}/logs
            chown hdfs:hadoop #{hadoop_home}/logs

            echo 'create hadoop command in /usr/bin/'
            cat <<EOF > /usr/bin/hadoop
#!/bin/sh
export HADOOP_HOME=#{hadoop_home}
exec #{hadoop_home}/bin/hadoop "\\$@"
EOF
            chmod 777 /usr/bin/hadoop
            test -d #{hadoop_home}
          }
        end

      end

      if ['namenode', 'datanode', 'jobtracker', 'tasktracker', 'secondarynamenode'].include?(component) then
        %W[#{node[:hadoop][:hadoop_handle]}-#{component}].each do |service_file|
          Chef::Log.info "installing #{service_file} as system service"
          template "/etc/init.d/#{service_file}" do
            owner "root"
            group "root"
            mode  "0755"
            variables( {:hadoop_version => hadoop_major_version} )
            source "#{service_file}.erb"
          end
        end
      end

      Chef::Log.info "Successfully installed package #{package_name}"
      return
    end

    # Install from rpm/apt packages
    package package_name do
      if node[:hadoop][:deb_version] != 'current'
        version node[:hadoop][:deb_version]
      end
    end
  end

  # Make a hadoop-owned directory
  def make_hadoop_dir dir, dir_owner, dir_mode="0755"
    directory dir do
      owner    dir_owner
      group    "hadoop"
      mode     dir_mode
      action   :create
      recursive true
    end
  end

  def ensure_hadoop_owns_hadoop_dirs dir, dir_owner, dir_mode="0755"
    execute "Make sure hadoop owns hadoop dirs" do
      command %Q{chown -R #{dir_owner}:hadoop #{dir}}
      command %Q{chmod -R #{dir_mode}         #{dir}}
      not_if{ (File.stat(dir).uid == dir_owner) && (File.stat(dir).gid == 300) }
    end
  end

  # Create a symlink to a directory, wiping away any existing dir that's in the way
  def force_link dest, src
    return if dest == src
    directory(dest) do
      action :delete ; recursive true
      not_if{ File.symlink?(dest) }
    end
    link(dest){ to src }
  end

  def local_hadoop_dirs
    dirs = node[:hadoop][:data_disks].map{ |mount_point, device| mount_point + '/hadoop' if File.exists?(node[:hadoop][:disk_devices][device]) }.compact!
    dirs.unshift('/mnt/hadoop') if node[:hadoop][:use_root_as_scratch_vol]
    dirs.uniq
  end

  def persistent_hadoop_dirs
    dirs = local_hadoop_dirs
    dirs.unshift('/mnt/hadoop') if node[:hadoop][:use_root_as_persistent_vol]
    dirs.uniq
  end

  # The HDFS data. Spread out across persistent storage only
  def dfs_data_dirs
    persistent_hadoop_dirs.map{|dir| File.join(dir, 'hdfs/data')}
  end
  # The HDFS metadata. Keep this on two different volumes, at least one persistent
  def dfs_name_dirs
    dirs = persistent_hadoop_dirs.map{|dir| File.join(dir, 'hdfs/name')}
    unless node[:hadoop][:extra_nn_metadata_path].nil?
      dirs << File.join(node[:hadoop][:extra_nn_metadata_path].to_s, node[:cluster_name], 'hdfs/name')
    end
    dirs
  end
  # HDFS metadata checkpoint dir. Keep this on two different volumes, at least one persistent.
  def fs_checkpoint_dirs
    dirs = persistent_hadoop_dirs.map{|dir| File.join(dir, 'hdfs/secondary')}
    unless node[:hadoop][:extra_nn_metadata_path].nil?
      dirs << File.join(node[:hadoop][:extra_nn_metadata_path].to_s, node[:cluster_name], 'hdfs/secondary')
    end
    dirs
  end
  # Local storage during map-reduce jobs. Point at every local disk.
  def mapred_local_dirs
    local_hadoop_dirs.map{|dir| File.join(dir, 'mapred/local')}
  end

  # Hadoop 0.23 requires hadoop directory path in conf files to be in URI format
  def formalize_dirs dirs
    if is_hadoop_yarn?
      'file://' + dirs.join(',file://')
    else
      dirs.join(',')
    end
  end

  # return true if installing hadoop 0.23
  def is_hadoop_yarn?
    node[:hadoop][:is_hadoop_yarn] == true
  end

  # HADOOP_HOME
  def hadoop_home_dir
    node[:hadoop][:hadoop_home_dir]
  end

  # Use `file -s` to identify volume type: ohai doesn't seem to want to do so.
  def fstype_from_file_magic(dev)
    return 'ext4' unless File.exists?(dev)
    dev_type_str = `file -s '#{dev}'`
    case
    when dev_type_str =~ /SGI XFS/           then 'xfs'
    when dev_type_str =~ /Linux.*ext2/       then 'ext2'
    when dev_type_str =~ /Linux.*ext3/       then 'ext3'
    else                                          'ext4'
    end
  end

  # this is just a stub to prevent code broken
  def all_cluster_volumes
    nil
  end

end

class Chef::Recipe
  include HadoopCluster
end
class Chef::Resource::Directory
  include HadoopCluster
end
