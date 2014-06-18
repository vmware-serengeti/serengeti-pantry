module HadoopCluster

  # Return user defined cluster configuration
  def all_conf
    conf = node['cluster_configuration'] || {} rescue conf = {}
    conf.dup
  end

end