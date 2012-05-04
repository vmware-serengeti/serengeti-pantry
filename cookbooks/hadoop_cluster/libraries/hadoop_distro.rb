module HadoopCluster
  def distro(name)
    data_bag_item("hadoop_distros", name)
  end

  def current_distro
    @current_distro ||= distro(node[:hadoop][:distro_name])
  end

  class Chef::Recipe ; include HadoopCluster ; end
  class Chef::Resource::Directory ; include HadoopCluster ; end
end