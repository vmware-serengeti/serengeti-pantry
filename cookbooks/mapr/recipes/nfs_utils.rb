#
#   Copyright (c) 2012-2013 VMware, Inc. All Rights Reserved.
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.
#

# install NFS utils
package 'nfs-utils'

# install RPC service
case node['platform']
when "redhat", "centos", "scientific", "oracle"
  if node['platform_version'].to_f >= 6.0
    pkg_name = 'rpcbind'
    svc_name = 'rpcbind'
  else
    pkg_name = 'portmap'
    svc_name = 'portmap'
  end
end

package pkg_name
service svc_name do
  action :start
end

