module HadoopCluster
  module Error

    BOOTSTRAP_ERRORS = {
      :COMMON_FAILURE => {
        :code => 'ERROR_BOOTSTARP_FAILURE',
        :msg => "Failed to bootstrap node %s :\n%s\n\nPlease ssh to this node and check log file /var/chef/cache/chef-stacktrace.out.\n" +
          "You can also run 'sudo chef-client' on the node to get error details."
      },
      :PACKAGE_FAILURE => {
        :code => 'ERROR_INSTALL_PACKAGE',
        :msg => "Failed to install package %s on node %s. Please ssh to this node and run 'sudo yum install %s' to find out why it failed."
      },
      :SERVICE_FAILURE => {
        :code => 'ERROR_SERVICE_FAILURE',
        :msg => "Failed to %s service %s on node %s. Please ssh to this node and run '%s' to find out why it failed."
      },
      :COMMAND_FAILURE => {
        :code => 'ERROR_COMMAND_FAILURE',
        :msg => "Failed to run command '%s' on node %s. Please ssh to this node and run 'sudo chef-client' to get error details."
      },
    }

  end
end