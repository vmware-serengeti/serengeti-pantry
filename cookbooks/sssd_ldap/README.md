sssd_ldap Cookbook
==================
[![Build Status](https://travis-ci.org/tas50/chef-sssd_ldap.svg?branch=master)](https://travis-ci.org/tas50/chef-sssd_ldap)

This cookbook installs SSSD and configures it for LDAP authentication

Requirements
------------

### Platform:

* Redhat
* Centos
* Amazon
* Scientific
* Oracle
* Ubuntu (10.04 / 12.04 / 14.04)

Attributes
----------
| Attribute | Value | Comment |
| -------------  | -------------  | -------------  |
| ['id_provider'] | 'ldap' | |
| ['auth_provider'] | 'ldap' | |
| ['chpass_provider'] | 'ldap' | |
| ['sudo_provider'] | 'ldap' | | 
| ['enumerate'] | 'true' | |
| ['cache_credentials'] | 'false' | |
| ['ldap_schema'] | 'rfc2307bis' | |
| ['ldap_uri'] | 'ldap://something.yourcompany.com' | |
| ['ldap_search_base'] | 'dc=yourcompany,dc=com' | |
| ['ldap_user_search_base'] | 'ou=People,dc=yourcompany,dc=com' | |
| ['ldap_user_object_class'] | 'posixAccount' | |
| ['ldap_user_name'] | 'uid' | |
| ['override_homedir'] | nil | |
| ['shell_fallback'] | '/bin/bash' | |
| ['ldap_group_search_base'] | 'ou=Groups,dc=yourcompany,dc=com' | |
| ['ldap_group_object_class'] | 'posixGroup' | |
| ['ldap_id_use_start_tls'] | 'true' | |
| ['ldap_tls_reqcert'] | 'never' | |
| ['ldap_tls_cacertdir'] | '/etc/pki/tls/certs' | |
| ['ldap_default_bind_dn'] | 'cn=bindaccount,dc=yourcompany,dc=com' | if you have a domain that doesn't require binding set this attributes to nil
| ['ldap_default_authtok'] | 'bind_password' | if you have a domain that doesn't require binding set this to nil | 
| ['authconfig_params'] | '--enablesssd --enablesssdauth --enablelocauthorize --update' | |
| ['access_provider'] | nil | Should be set to 'ldap' |
| ['ldap_access_filter'] | nil| Can use simple LDAP filter such as 'uid=abc123' or more expressive LDAP filters like '(&(objectClass=employee)(department=ITSupport))' | 
| ['min_id'] | '1' | default, used to ignore lower uid/gid's | 
| ['max_id'] | '0' | default, used to ignore higher uid/gid's | 
| ['ldap_sudo'] | 'false' | Adds ldap enabled sudoers (true/false) |


Recipes
-------

*default: Installs and configures sssd daemon

License and Author
------------------

Author:: Tim Smith - (<tsmith84@gmail.com>)

Copyright:: 2013-2014, Limelights Networks, Inc

License:: Apache 2.0

