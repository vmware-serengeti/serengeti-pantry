module HadoopCluster
  ACTION_INSTALL_PACKAGE = 'Installing package <obj>'
  ACTION_START_SERVICE = 'Starting service <obj>'

  # Save Bootstrap Status to Chef::Node.
  def set_bootstrap_action(act = '', obj = '')
    act = act.gsub(/<obj>/, obj)
    ruby_block "Set Bootstrap action to '#{act}'" do
      block do
        attrs = node[:provision] ? node[:provision].to_hash : Hash.new
        attrs['action'] = act
        node[:provision] = attrs
        node.save
      end
      action :create
    end
  end

  class Chef::Recipe ; include HadoopCluster ; end
  class Chef::Resource::Directory ; include HadoopCluster ; end
end
