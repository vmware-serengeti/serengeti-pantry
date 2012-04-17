# Defines a machine acting as a Hadoop Client to submit Hadoop jobs

# Must have ruby-shadow installed for password support when creating a user.
gem_package "ruby-shadow" do
  action :install
end

# create a user
user 'joe' do
  comment    'A sample user for submitting Hadoop jobs'
  home       "/var/lib/joe"
  shell      "/bin/bash"
  password   'password'
  supports   :manage_home => true
  action     [:create, :manage]
end
