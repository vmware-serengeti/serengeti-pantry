module HadoopCluster
  module Error

    BOOTSTRAP_ERRORS = {
      :COMMON_FAILURE => {
        :code => 'ERROR_BOOTSTARP_FAILURE',
        :msg => "Cannot bootstrap node %s.\n%s\nSSH to this node and view the log file /var/chef/cache/chef-stacktrace.out, or run the command 'sudo chef-client' to view error messages."
      },
      :PACKAGE_FAILURE => {
        :code => 'ERROR_INSTALL_PACKAGE',
        :msg => "Cannot install package %s on node %s. SSH to this node and run the command 'sudo yum install %s -y' to view error messages."
      },
      :PACKAGE_REPO_FAILURE => {
        :code => 'PACKAGE_REPO_FAILURE',
        :msg => "Cannot install package %s on node %s. The yum repo you set for the distro doesn't work. " +
          "Are you using a yum repo for RHEL/CentOS 5? We expect the repo for RHEL/CentOS 6. Or are the rpm files in the yum repo broken?\n" +
          "SSH to this node and run 'sudo yum install %s -y' to view error messages."
      },
      :SERVICE_FAILURE => {
        :code => 'ERROR_SERVICE_FAILURE',
        :msg => "Cannot %s service %s on node %s. SSH to this node and run the command '%s' to view error messages."
      },
      :COMMAND_FAILURE => {
        :code => 'ERROR_COMMAND_FAILURE',
        :msg => "Unable to run command '%s' on node %s. SSH to this node and run the command 'sudo chef-client' to view error messages."
      },
    }

  end
end