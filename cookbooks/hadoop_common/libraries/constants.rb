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
        :msg => "Unable to install package %s on node %s using the specified Yum repository. The RPM files may be damaged, or intended for a different operating system version. SSH to this node and run 'sudo yum install %s -y' to view error messages."
      },
      :SERVICE_FAILURE => {
        :code => 'ERROR_SERVICE_FAILURE',
        :msg => "Cannot %s service %s on node %s. SSH to this node and run the command '%s' to view error messages."
      },
      :COMMAND_FAILURE => {
        :code => 'ERROR_COMMAND_FAILURE',
        :msg => "Unable to run command '%s' on node %s. SSH to this node and run the command 'sudo chef-client' to view error messages."
      },
      :FQDN_RESOLUTION_FAILURE => {
        :code => 'ERROR_FQDN_RESOLUTION_FAILURE',
        :msg => "Unable to resolve the IP address %s to the FQDN on node %s. To deploy Hadoop 2.x the DNS server must provide forward and reverse FQDN/IP resolution."
      },
    }

  end
end