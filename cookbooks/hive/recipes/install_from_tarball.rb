include_recipe "install_from"

# Load distro repository info
tarball_url = current_distro['hive']
Chef::Log.info "Installing tarball from #{tarball_url}"

install_from_release('hive') do
  release_url   tarball_url
  home_dir      node[:hive][:home_dir]
  version       node[:hive][:version]
  action        [:install]
  has_binaries  [ 'bin/hive' ]

  not_if { ::File.exists?("#{node[:hive][:home_dir]}/hive.jar") }
end
