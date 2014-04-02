#
#   Copyright (c) 2012-2013 VMware, Inc. All Rights Reserved.
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0

#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

module HadoopCluster
  def distro(name)
    data_bag_item("hadoop_distros", name)
  end

  def current_distro
    @current_distro ||= distro(node[:hadoop][:distro_name])
  end

  def distro_vendor
    node[:hadoop][:distro_vendor]
  end

  def distro_version
    node[:hadoop][:distro_version]
  end

  def package_repos
    current_distro['package_repos'] || []
  end

  # is a hadoop 2.0+ distro? Hadoop 2.0 contains HDFS2 and YARN
  # cdh4 contains both Hadoop 1.0 (MRv1) and Hadoop 2.0
  def is_hadoop2_distro
    is_pivotalhd_distro || is_hdp2_distro || is_bigtop_hadoop2_distro || is_intel_hadoop2_distro
  end

  # is a hadoop 1.x or 0.20 distro?
  def is_hadoop1_distro
    !is_hadoop2_distro
  end

  def is_install_from_tarball
    current_distro['is_install_from_tarball']
  end

  def is_cdh4_distro
    distro_vendor.downcase == 'cdh' and distro_version.to_f >= 4
  end

  def is_greenplumhd_distro
    distro_vendor.downcase == 'gphd'
  end

  def is_pivotalhd_distro
    distro_vendor.downcase == 'phd' or (is_greenplumhd_distro and (distro_version =~ /2/) == 0)
  end

  def is_intel_distro
    distro_vendor.downcase == 'intel'
  end

  def is_intel_hadoop1_distro
    distro_vendor.downcase == 'intel' and distro_version.to_f < 3
  end

  def is_intel_hadoop2_distro
    distro_vendor.downcase == 'intel' and distro_version.to_f >= 3
  end

  def is_hdp1_distro
    distro_vendor.downcase == 'hdp' and distro_version.to_f < 2
  end

  def is_hdp2_distro
    distro_vendor.downcase == 'hdp' and distro_version.to_f >= 2
  end

  def is_bigtop_hadoop1_distro
    distro_vendor.downcase == 'bigtop' and distro_version.to_f < 0.4
  end

  def is_bigtop_hadoop2_distro
    distro_vendor.downcase == 'bigtop' and distro_version.to_f >= 0.4
  end

  # Return hadoop version as string.
  # Use hadoop_version.to_f to get the major.minor version as float.
  # Use hadoop_version.to_i to get the major version as int.
  def hadoop_version
    `hadoop version | head -1 | awk '{print $2}'`.strip rescue "1.0"
  end

  def is_hadoop2
    hadoop_version.to_i >= 2
  end

  class Chef::Recipe ; include HadoopCluster ; end
  class Chef::Resource::Directory ; include HadoopCluster ; end
end
