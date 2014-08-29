#
# Cookbook Name::       pig
# Description::         Installs pig from the cloudera package -- verified compatible, but on a slow update schedule.
# Recipe::              install_from_package
# Author::              Philip (flip) Kromer - Infochimps, Inc
#
# Copyright 2009, Opscode, Inc.
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

include_recipe "hadoop_common::add_repo"

#
# Install package
#
package node[:hadoop][:packages][:pig][:name] do
  retries 6
  retry_delay 5
end

