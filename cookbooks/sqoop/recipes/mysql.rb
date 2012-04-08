#
# Cookbook Name:: sqoop
# Recipe:: mysql
#
# Copyright 2012, VMware Inc.
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

execute "Install mysql jdbc driver to Sqoop lib directory" do
  not_if do File.exists?("#{node[:sqoop][:sqoop_home]}/lib/#{node[:sqoop][:mysql_jdbc_driver]}-bin.jar") end
    
  command %Q{
    cd #{node[:sqoop][:sqoop_home]}/lib
    wget "http://www.mysql.com/get/Downloads/Connector-J/#{node[:sqoop][:mysql_jdbc_driver]}.tar.gz/from/http://mysql.he.net/"
    tar -xzf #{node[:sqoop][:mysql_jdbc_driver]}.tar.gz  #{node[:sqoop][:mysql_jdbc_driver]}/#{node[:sqoop][:mysql_jdbc_driver]}-bin.jar
    mv #{node[:sqoop][:mysql_jdbc_driver]}/#{node[:sqoop][:mysql_jdbc_driver]}-bin.jar ./
    rm -rf #{node[:sqoop][:mysql_jdbc_driver]}
    rm #{node[:sqoop][:mysql_jdbc_driver]}.tar.gz
  }
end
      
