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

require 'chef/handler'

class Chef
  class Handler
    class Serengeti < ::Chef::Handler

      include HadoopCluster
      include HadoopCluster::Error

      def report
        if exception
          node_name = data[:node].name
          msg = exception.message
          err_msg = ''
          case exception.class.to_s
            when 'Chef::Exceptions::Package'
              pkg_name = msg.slice(msg.index('[') + 1 ... msg.index(']'))
              err_msg = BOOTSTRAP_ERRORS[:PACKAGE_FAILURE][:msg] % [pkg_name, node_name, pkg_name]
            when 'Chef::Exceptions::Exec'
              if msg.start_with?('package[')
                pkg_name = msg.slice(msg.index('[') + 1 ... msg.index(']'))
                err_msg = BOOTSTRAP_ERRORS[:PACKAGE_REPO_FAILURE][:msg] % [pkg_name, node_name, pkg_name]
              else
                err_msg = BOOTSTRAP_ERRORS[:COMMON_FAILURE][:msg] % [node_name, exception.to_s]
              end
            when 'Mixlib::ShellOut::ShellCommandFailed'
              if msg.start_with?('service[')
                # service operation failed
                # on CentOS #{cmd} is like this: sudo /sbin/service hbase-regionserver start
                cmd = 'sudo ' + msg.slice(msg.rindex('Ran ') + 'Ran '.length ... msg.index(" returned "))
                array = cmd.split(' ')
                svc_name = array[2]
                svc_action = array[3]
                err_msg = BOOTSTRAP_ERRORS[:SERVICE_FAILURE][:msg] % [svc_action, svc_name, node_name, cmd]
              elsif msg.start_with?('execute[')
                cmd = msg.slice(msg.index('execute[') .. msg.index(']'))
                err_msg = BOOTSTRAP_ERRORS[:COMMAND_FAILURE][:msg] % [cmd, node_name]
              else
                err_msg = BOOTSTRAP_ERRORS[:COMMON_FAILURE][:msg] % [node_name, exception.to_s]
              end
            else
              err_msg = BOOTSTRAP_ERRORS[:COMMON_FAILURE][:msg] % [node_name, exception.to_s]
          end
          Chef::Log.fatal err_msg
          set_error_msg(err_msg)
        end
      end

    end
  end
end