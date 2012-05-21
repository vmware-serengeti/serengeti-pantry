#
# Cookbook Name::       pig
# Description::         Install From the release tarball.
# Recipe::              install_from_release
# Author::              Philip (flip) Kromer - Infochimps, Inc
#
# Copyright 2009, Infochimps, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

include_recipe "pig::default"
include_recipe "install_from"

# Load distro repository info
tarball_url = current_distro['pig']
unless ::File.exists?("#{node[:pig][:home_dir]}")
  Chef::Log.info "Installing tarball from #{tarball_url}"
  set_bootstrap_action(ACTION_INSTALL_PACKAGE, 'hive')
end

#
# Install pig from latest release
#
#   puts pig tarball into /usr/local/src/pig-xxx
#   expands it into /usr/local/share/pig-xxx
#   and links that to /usr/local/share/pig
#

install_from_release('pig') do
  release_url   tarball_url
  home_dir      node[:pig][:home_dir]
  version       node[:pig][:version]
  action        [:install]
  has_binaries  [ 'bin/pig' ]

  not_if{ ::File.exists?("#{node[:pig][:home_dir]}") }
end
