#
#   Copyright (c) 2012-2014 VMware, Inc. All Rights Reserved.
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
  OBJECT_NONE = 'set_action'
  ACTION_NONE = ''
  ACTION_INSTALL_PACKAGE = 'Installing package <obj>'
  ACTION_START_SERVICE = 'Starting service <obj>'
  ACTION_WAIT_FOR_SERVICE = 'Waiting for the nodes running service <obj>'
  ACTION_FORMAT_DISK = 'Formatting data disks'

  # Save Bootstrap Status to Chef::Node. It will be ran in Chef converge phase.
  def set_bootstrap_action(act = '', obj = '', run = false)
    return if ACTION_INSTALL_PACKAGE == act and package_installed?(obj)
    obj = OBJECT_NONE if obj.to_s.empty?
    ruby_block "#{obj}" do
      block do
        set_action(act, obj)
      end
      action run ? :create : :nothing
    end
  end

  def clear_bootstrap_action
    set_bootstrap_action(ACTION_NONE, OBJECT_NONE, true)
  end

  # Save Bootstrap Status to Chef::Node. It will be ran in Chef compile phase.
  def set_action(act = '', obj = '')
    act ||= ''
    obj ||= ''

    # if the package is already installed, no need to set action.
    # obj can be "package_a package_b ..."
    return if ACTION_INSTALL_PACKAGE == act and package_installed?(obj)

    act = act.gsub(/<obj>/, obj)
    attrs = node[:provision] ? node[:provision].dup : Mash.new
    if attrs[:action] != act
      Chef::Log.info "Set Bootstrap Action to '#{act}'"
      attrs[:action] = act
      node.normal[:provision] = attrs
      node.save
    end
  end

  def clear_action
    set_action('', '')
  end

  def set_error_msg(msg = '')
    attrs = node[:provision] ? node[:provision].dup : Mash.new
    if attrs[:error_msg] != msg
      Chef::Log.debug "Set Bootstrap Error Msg to '#{msg}'"
      attrs[:error_msg] = msg
      node.normal[:provision] = attrs
      node.save
    end
  end

  def clear_error_msg
    set_error_msg('')
  end

  class Chef::Recipe ; include HadoopCluster ; end
  class Chef::Resource::Directory ; include HadoopCluster ; end
  class Chef::Resource::RubyBlock ; include HadoopCluster ; end
end
