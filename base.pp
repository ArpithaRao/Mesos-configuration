########################################################################
# base.pp
#
# This is the base node manifest.  Configuration here is 
# applied to all nodes.
#
########################################################################

node 'base' {

  include stdlib

########################################################################
#
# ENVIRONMENT GLOBALS
#
########################################################################

    $local_dns_domain        = 'lab.lynx-connected.com'

    $local_kerberos_realm    = 'LAB.LYNX-CONNECTED.COM'

    $local_kdc_servers       = [ "a1-dev-aut001.${local_dns_domain}" , ]

    $local_admin_server      = "a1-dev-aut001.${local_dns_domain}"

    $local_gateway           =  '16.73.16.1'

    $env_def_fw_interface           =  'ens32'

    $env_puppet_master           =  "a1-dev-pms002.lab.lynx-connected.com"

    $env_puppet_runinterval  = '3600'

    $env_puppet_enabled      = 'false'

    $env_puppet_service      = 'stopped'

    $yum_package_host           =  "a1-dev-pkg003.lab.lynx-connected.com"

    #This is intended to be a bogus host in Development. It is overriden later to point to a valid 
    #node for the dev stack. This avoids have all backend nodes pointing at a single Ganglia node.
    $def_monitoring_host     = "a1-dev-mon999.${local_dns_domain}"

    $syslog_hosts            = [ "a1-dev-log001.${local_dns_domain}" ,
                                 "a1-dev-log002.${local_dns_domain}" , ]

    $smtp_relay_host         = "a1-dev-pfx001.${local_dns_domain}"

    $local_dns_servers       = [ '16.73.20.123' , 
                                 '16.73.20.124' , ]

    $public_dns_servers      = [ '16.73.28.11' ,
                                 '16.73.28.12' , ]

    $local_ntp_servers       = [ "a1-dev-dns001.${local_dns_domain}" ,
                                 "a1-dev-dns002.${local_dns_domain}" , ]

    $public_ntp_servers      = [ 'time.nist.gov' ,
                                 'nist1-chi.ustiming.org' ,
                                 'nist1-sj.ustiming.org' , ]

    $local_ldap_auth_servers = [ "ldap://a1-dev-aut001.${local_dns_domain}" ,
                                 "ldap://a1-dev-aut002.${local_dns_domain}" , ]

    $local_ldap_auth_base_dn = [ "dc=hp", "dc=com" , ]

    $admin_email_address     = 'root@localhost'

    $env_bootstrap_admins    = [ 'cmxa' , 'lynxa' , 'lynxe' , ]

    $ssh_allowed_groups      = [ 'cmxa' , 'lynxa' , 'lynxe' , ]

    $env_mco_pool_hosts      = [ "a1-dev-rmq001.${local_dns_domain}" , ]

    $env_mco_user            = 'mcollective'

    $env_mco_password        = 'Password1'

    $env_mco_psk             = 'P8ssw0rd5678'
	
	$env_jre_pkg_name        = 'jre1.8.0_73'

    $env_jre_pkg_version     = '1.8.0_73-fcs'

    $env_jre_java_home       = '/usr/java/jre1.8.0_73'
	
	$env_jdk_pkg_name        = 'jdk1.8.0_73'

    $env_jdk_pkg_version     = '1.8.0_73-fcs'

    $env_jdk_java_home       = '/usr/java/jdk1.8.0_73'


########################################################################
#
# ENVIRONMENT SSL
#
########################################################################

# If the environment SSL mode is set to certmaster, nodes will deploy
# the certmaster/certmonger/func package installation and config,
# with the expectation that a server in the environment is acting
# as the certmaster master.  In this setup, SSL certificate exchange
# happens automatically, with self-signed server certificates 
# valid for ten years.
#
# If the SSL mode is set to wildcard, Puppet will deploy a wildcard
# cert to all nodes and present this cert in all SSL-secured services.
# The wildcard cert must be manually obtained and placed in 
# modules/sslcert/files .  
#

    $env_ssl_mode = 'wildcard'

    class { 'openssl': }

    class { 'haveged': }

########################################################################
#
# ENVIRONMENT OBJECT STORAGE
#
########################################################################

# Environments can either be configured to store data locally or in 
# cloud object storage.  This section contains environment globals
# related to cloud authentication and storage endpoints.  
#

    $env_storage_type = 'hpcloud'

    $env_storage_provider_name = 'HPCloud East'

    $env_storage_provider_id = 'hpcloud.east'

    $env_storage_provider_type = 'swift'

# In HP Helion Public Cloud the storage provider endpoint should end in
# v1/ but in Helion OpenStack environments it should end in v1/AUTH_

    $env_storage_provider_endpoint           =  "https://16.73.59.17:8080/v1/AUTH_"


    $env_storage_provider_authentication_type ='keystonev2'

    $env_storage_provider_container_threshold = '990000'           

    $env_storage_provider_object_container_threshold = '990000'  

# Remove any leading prefixes and only put the ID for tenant ID

    $env_keystone_tenant_id           =  "d81e03a2ab6d46e996cecdefb2edc611"

    $env_keystone_endpoint           =  "https://16.73.59.17:5000/v2.0/tokens"
    
# In HP Helion Public Cloud the credentials type should be set to 
# accesskey
#
# In other Helion environments change the credentials type to password    

    $env_keystone_credentials_type           =  "password"

    $env_keystone_expiry = '3'

    $env_swift_connection_timeout = '10000'

    $env_swift_read_timeout = '60000'

    $env_openstack_project_name_prefix           =  "CMX_SOU_Dev"

########################################################################
#
# ENVIRONMENT TIME ZONE
#
########################################################################

    class { 'timezone': 
              timezone_name   => 'UTC' ,
    }

########################################################################
#
# NETWORK & DNS
#
########################################################################

    class { 'sysconfig::network': 
              gateway         => extlookup("localGateway", $local_gateway ) ,
              gateway_dev     => extlookup("gatewayDev", $env_def_fw_interface) ,
    }

    class { 'etc::resolv':
              dns_domain      => $local_dns_domain ,
              dns_nameservers => $local_dns_servers ,
              stage           => 'bootstrap',
    }

########################################################################
#
# NOTIFY BANNER
#
########################################################################

# The notify banner appears during each Puppet run and is helpful in 
# observing how Puppet has identified a node and what configuration
# it will receive.
#

    notify { 'Deployment Notification':

        message => "Node Identification -- Environment: ${platform} Region: ${region} AZ: ${availabilityzone}, Stack: ${stack} Node Type: ${nodetype}",
    }

########################################################################
#
# SYSTEM PROMPT
#
########################################################################

    $redPrompt = '\[\e[0;31m\][\u@\h \W]\$ \[\e[m\]'
    $greenPrompt = '\[\e[0;32m\][\u@\h \W]\$ \[\e[m\]'
    $yellowPrompt = '\[\e[0;33m\][\u@\h \W]\$ \[\e[m\]'
    $cyanPrompt = '\[\e[0;36m\][\u@\h \W]\$ \[\e[m\]'


    # Set the prompt colour for the system:
    # Production: RED
    # Pre-Production: CYAN
    # QA/Integration: YELLOW
    # Dev: GREEN

    file { "/etc/profile.d/prompt.sh":
        content => $stack ? {
            default       => "PS1=\"${redPrompt}\"" ,
            'dev'         => "PS1=\"${greenPrompt}\"" ,
            'qa'          => "PS1=\"${yellowPrompt}\"" ,
            'integration' => "PS1=\"${yellowPrompt}\"" ,
            'perf'        => "PS1=\"${yellowPrompt}\"" ,
            'demo'        => "PS1=\"${yellowPrompt}\"" ,
            'test1'       => "PS1=\"${yellowPrompt}\"" ,
            'test2'       => "PS1=\"${yellowPrompt}\"" ,
            'preprod'     => "PS1=\"${cyanPrompt}\"" ,
            'sandbox'     => "PS1=\"${redPrompt}\"" ,
            'production'  => "PS1=\"${redPrompt}\"" ,
        }
     }

########################################################################
#
# ENVIRONMENT YUM REPOSITORIES
#
########################################################################

  class { 'repo::yum_clean': }

  $centosRepoUrl = $stack ? {
    default     => extlookup("centosPrivateRepoUrl", "https://${yum_package_host}/centos/unstable/") ,
    dev         => extlookup("centosPrivateRepoUrl", "https://${yum_package_host}/centos/unstable/") ,
    qa          => extlookup("centosPrivateRepoUrl", "https://${yum_package_host}/centos/unstable/") ,
    integration => "https://${yum_package_host}/centos/stable/os/x86_64/" ,
    test1       => "https://${yum_package_host}/centos/stable/os/x86_64/" ,
    test2       => "https://${yum_package_host}/centos/stable/os/x86_64/" ,
    sandbox     => "https://${yum_package_host}/centos/stable/os/x86_64/" ,
    preprod     => "https://${yum_package_host}/centos/stable/" ,
    production  => "https://${yum_package_host}/centos/stable/" ,
    performance => "https://${yum_package_host}/centos/stable/os/x86_64/" ,
    demo        => "https://${yum_package_host}/centos/unstable/" ,
  }

  class { 'repo::centosrepo':
            repo_enabled    => extlookup("centosPublicRepoEnabled", "1") ,
  }

  class { 'repo::centosprivate':
            baseurl         => $centosRepoUrl ,
            enabled         => extlookup("centosPrivateRepoEnabled", "0") ,
            gpgcheck        => extlookup("centosPrivateRepoGpgcheck", "0") ,
            metadata_expire => extlookup("centosPrivateRepoMetadataExpire", "60m") ,
            sslverify       => 'False' ,
  }

  $epelRepoUrl = $stack ? {
    default     => extlookup("epelPrivateRepoUrl", "https://${yum_package_host}/epel/unstable/") ,
    dev         => extlookup("epelPrivateRepoUrl", "https://${yum_package_host}/epel/unstable/") ,
    qa          => extlookup("epelPrivateRepoUrl", "https://${yum_package_host}/epel/unstable/") ,
    integration => "https://${yum_package_host}/epel/stable/x86_64/" ,
    test1       => "https://${yum_package_host}/epel/stable/x86_64/" ,
    test2       => "https://${yum_package_host}/epel/stable/x86_64/" ,
    sandbox     => "https://${yum_package_host}/epel/stable/x86_64/" ,
    preprod     => "https://${yum_package_host}/epel/stable/" ,
    production  => "https://${yum_package_host}/epel/stable/" ,
    performance => "https://${yum_package_host}/epel/stable/x86_64/" ,
    demo        => "https://${yum_package_host}/epel/unstable/" ,
  }

  class { 'repo::epelrepo':
            repo_enabled    => extlookup("epelPublicRepoEnabled", "0") ,
  }

  class { 'repo::epelprivate':
            baseurl         => $epelRepoUrl ,
            enabled         => extlookup("epelPrivateRepoEnabled", "1") ,
            gpgcheck        => extlookup("epelPrivateRepoGpgcheck", "0") ,
            metadata_expire => extlookup("epelPrivateRepoMetadataExpire", "60m") ,
            sslverify       => 'False' ,
  }

  $tpRepoUrl = $stack ? {
    default     => extlookup("tpRepo", "https://${yum_package_host}/tp/stable/") ,
    dev         => extlookup("tpRepo", "https://${yum_package_host}/tp/stable/") ,
    qa          => extlookup("tpRepo", "https://${yum_package_host}/tp/stable/") ,
    integration => "https://${yum_package_host}/tp/stable/" ,
    test1       => "https://${yum_package_host}/tp/stable/" ,
    test2       => "https://${yum_package_host}/tp/stable/" ,
    sandbox     => "https://${yum_package_host}/tp/stable/" ,
    preprod     => "https://${yum_package_host}/tp/stable/" ,
    production  => "https://${yum_package_host}/tp/stable/" ,
    performance => "https://${yum_package_host}/tp/stable/" ,
    demo        => "https://${yum_package_host}/tp/unstable/" ,
  }

  class { 'repo::tprepo':
            baseurl         => $tpRepoUrl ,
            enabled         => extlookup("tpRepoEnabled", "1") ,
            gpgcheck        => extlookup("tpRepoGpgcheck", "0") ,
            metadata_expire => extlookup("tpRepoMetadataExpire", "60") ,
            sslverify       => 'False' ,
  }

  $appRepoUrl = $stack ? {
    default     => extlookup("appRepo", "http://reyum.englab.local/yum/lynx-4.0.0/continuous/") ,
    dev         => extlookup("appRepo", "http://reyum.englab.local/yum/lynx-4.0.0/continuous/") ,
    qa          => extlookup("appRepo", "http://reyum.englab.local/yum/lynx-4.0.0/continuous/") ,
    integration => "http://reyum.englab.local/yum/lynx-3.0.0/nightly/" ,
    test1       => "http://reyum.englab.local/yum/lynx-3.0.0/nightly/" ,
    test2       => "http://reyum.englab.local/yum/lynx-3.0.0/nightly/" ,
    sandbox     => "http://reyum.englab.local/yum/lynx-3.0.0/nightly/" ,
    preprod     => "https://${yum_package_host}/app/current/" ,
    production  => "https://${yum_package_host}/app/current/" ,
    performance => "http://reyum.englab.local/yum/lynx/nightly/" ,
    demo        => "http://reyum.englab.local/yum/lynx/nightly/" ,
  }

  class { "repo::apprepo":
            baseurl         => $appRepoUrl ,
            enabled         => extlookup("appRepoEnabled", "1") , 
            gpgcheck        => extlookup("appRepoGpgcheck", "0") ,
            metadata_expire => extlookup("appRepoMetadataExpire", "15m") ,
            sslverify       => 'False' ,
  }

  $pgRepoUrl = $stack ? {
    default     => extlookup("pgPrivateRepoUrl", "https://${yum_package_host}/postgres/unstable/") ,
    dev         => extlookup("pgPrivateRepoUrl", "https://${yum_package_host}/postgres/unstable/") ,
    qa          => extlookup("pgPrivateRepoUrl", "https://${yum_package_host}/postgres/unstable/") ,
    integration => "https://${yum_package_host}/postgres/stable/" ,
    test1       => "https://${yum_package_host}/postgres/stable/" ,
    test2       => "https://${yum_package_host}/postgres/stable/" ,
    sandbox     => "https://${yum_package_host}/postgres/stable/" ,
    preprod     => "https://${yum_package_host}/postgres/stable/" ,
    production  => "https://${yum_package_host}/postgres/stable/" ,
    performance => "https://${yum_package_host}/postgres/stable/" ,
    demo        => "https://${yum_package_host}/postgres/unstable/" ,
  }

  class { 'repo::pgrepo':
            repo_enabled    => extlookup("pgPublicRepoEnabled", "0") ,
  }

  class { 'repo::pgprivate':
            baseurl         => $pgRepoUrl ,
            enabled         => extlookup("pgPrivateRepoEnabled", "1") , 
            gpgcheck        => extlookup("pgPrivateRepoGpgcheck", "0") ,
            metadata_expire => extlookup("pgPrivateRepoMetadataExpire", "60m") ,
            sslverify       => 'False' ,
  }

  $mysqlRepoUrl = $stack ? {
    default     => extlookup("mysqlPrivateRepoUrl", "https://${yum_package_host}/mysql/unstable/") ,
    dev         => extlookup("mysqlPrivateRepoUrl", "https://${yum_package_host}/mysql/unstable/") ,
    qa          => extlookup("mysqlPrivateRepoUrl", "https://${yum_package_host}/mysql/unstable/") ,
    integration => "https://${yum_package_host}/mysql/stable/" ,
    test1       => "https://${yum_package_host}/mysql/stable/" ,
    test2       => "https://${yum_package_host}/mysql/stable/" ,
    sandbox     => "https://${yum_package_host}/mysql/stable/" ,
    preprod     => "https://${yum_package_host}/mysql/stable/" ,
    production  => "https://${yum_package_host}/mysql/stable/" ,
    performance => "https://${yum_package_host}/mysql/stable/" ,
    demo        => "https://${yum_package_host}/mysql/unstable/" ,
  }

  class { 'repo::mysqlrepo':
            repo_enabled    => extlookup("mysqlPublicRepoEnabled", "0") ,
            mysql_version   => extlookup("mysqlVersion", "5.5") ,
  }

  class { 'repo::mysqlprivate':
            baseurl         => $mysqlRepoUrl ,
            enabled         => extlookup("mysqlPrivateRepoEnabled", "1") ,
            gpgcheck        => extlookup("mysqlPrivateRepoGpgcheck", "0") ,
            metadata_expire => extlookup("mysqlPrivateRepoMetadataExpire", "60m") ,
            sslverify       => 'False' ,
  }

  $puppetRepoUrl = $stack ? {
    default     => extlookup("puppetPrivateRepoUrl", "https://${yum_package_host}/puppetlabs/unstable/") ,
    dev         => extlookup("puppetPrivateRepoUrl", "https://${yum_package_host}/puppetlabs/unstable/") ,
    qa          => extlookup("puppetPrivateRepoUrl", "https://${yum_package_host}/puppetlabs/unstable/") ,
    integration => "https://${yum_package_host}/puppetlabs/stable/6/products/x86_64/" ,
    test1       => "https://${yum_package_host}/puppetlabs/stable/6/products/x86_64/" ,
    test2       => "https://${yum_package_host}/puppetlabs/stable/6/products/x86_64/" ,
    sandbox     => "https://${yum_package_host}/puppetlabs/stable/6/products/x86_64/" ,
    preprod     => "https://${yum_package_host}/puppetlabs/stable/" ,
    production  => "https://${yum_package_host}/puppetlabs/stable/" ,
    performance => "https://${yum_package_host}/puppetlabs/stable/6/products/x86_64/" ,
    demo        => "https://${yum_package_host}/puppetlabs/unstable/" ,
  }

  class { 'repo::puppetrepo':
            repo_enabled    => extlookup("puppetPublicRepoEnabled", "0") ,
  }

  class { 'repo::puppetprivate':
            baseurl         => $puppetRepoUrl ,
            enabled         => extlookup("puppetPrivateRepoEnabled", "1") ,
            gpgcheck        => extlookup("puppetPrivateRepoGpgcheck", "0") ,
            metadata_expire => extlookup("puppetPrivateRepoMetadataExpire", "60m") ,
            sslverify       => 'False' ,
  }

  $erlangRepoUrl = $stack ? {
    default     => extlookup("erlangPrivateRepoUrl", "https://${yum_package_host}/erlang/unstable/") ,
    dev         => extlookup("erlangPrivateRepoUrl", "https://${yum_package_host}/erlang/unstable/") ,
    qa          => extlookup("erlangPrivateRepoUrl", "https://${yum_package_host}/erlang/unstable/") ,
    integration => "https://${yum_package_host}/erlang/stable/" ,
    test1       => "https://${yum_package_host}/erlang/stable/" ,
    test2       => "https://${yum_package_host}/erlang/stable/" ,
    sandbox     => "https://${yum_package_host}/erlang/stable/" ,
    preprod     => "https://${yum_package_host}/erlang/stable/" ,
    production  => "https://${yum_package_host}/erlang/stable/" ,
    performance => "https://${yum_package_host}/erlang/stable/" ,
    demo        => "https://${yum_package_host}/erlang/unstable/" ,
  }

  class { 'repo::erlangrepo':
            repo_enabled    => extlookup("erlangPublicRepoEnabled", "0") ,
  }

  class { 'repo::erlangprivate':
            baseurl         => $erlangRepoUrl ,
            enabled         => extlookup("erlangPrivateRepoEnabled", "1") ,
            gpgcheck        => extlookup("erlangPrivateRepoGpgcheck", "0") ,
            metadata_expire => extlookup("erlangPrivateRepoMetadataExpire", "60m") ,
            sslverify       => 'False' ,
  }

#
# Determine which Ganglia host based on the stack
#
  $monitoring_host = $stack ? {
    default     => $def_monitoring_host,
    dev         => "a1-dev-mon002.${local_dns_domain}" ,
    qa          => "a1-qa-mon001.${local_dns_domain}" ,
    integration => $def_monitoring_host ,
    test1       => $def_monitoring_host ,
    test2       => $def_monitoring_host ,
    sandbox     => $def_monitoring_host ,
    preprod     => $def_monitoring_host ,
    production  => $def_monitoring_host ,
    performance => $def_monitoring_host ,
    demo        => $def_monitoring_host ,
  }

# We do not currently use Cloudera CDH to deploy our Hadoop stack.  
# This may change at some point, so we leave support for their Yum
# repository , but for security purposes we comment it out so that 
# it does not get deployed anywhere.

#  $cdhRepoUrl = $stack ? {
#    default     => extlookup("cdhPrivateRepoUrl", "https://${yum_package_host}/cdh/unstable/x86_64/") ,
#    dev         => extlookup("cdhPrivateRepoUrl", "https://${yum_package_host}/cdh/unstable/x86_64/") ,
#    qa          => extlookup("cdhPrivateRepoUrl", "https://${yum_package_host}/cdh/unstable/x86_64/") ,
#    integration => "https://${yum_package_host}/cdh/stable/x86_64/" ,
#    test1       => "https://${yum_package_host}/cdh/stable/x86_64/" ,
#    test2       => "https://${yum_package_host}/cdh/stable/x86_64/" ,
#    sandbox     => "https://${yum_package_host}/cdh/stable/x86_64/" ,
#    preprod     => "https://${yum_package_host}/cdh/stable/x86_64/" ,
#    production  => "https://${yum_package_host}/cdh/stable/x86_64/" ,
#    performance => "https://${yum_package_host}/cdh/stable/x86_64/" ,
#    demo        => "https://${yum_package_host}/cdh/unstable/" ,
#  }
#
#   $deploy_cdhrepos = [ 'dev' ]
#
#   if $stack in $deploy_cdhrepos {
#
#      class { 'cdhrepo':
#            repo_enabled    => extlookup("cdhPublicRepoEnabled", "0") ,
#            gpgcheck        => extlookup("cdhPublicRepoGpgcheck", "0") ,
#      }

#      class { 'repo::cdhprivate':
#            baseurl         => $cdhRepoUrl ,
#            enabled         => extlookup("cdhPrivateRepoEnabled", "0") ,
#            gpgcheck        => extlookup("cdhPrivateRepoGpgcheck", "0") ,
#            metadata_expire => extlookup("cdhPrivateRepoMetadataExpire", "60m") ,
#            sslverify       => 'False' ,
#      }
#   }

########################################################################
#
# SSH & ENVIRONMENT AUTHENTICATION
#
########################################################################

    class { 'kerberos::workstation': 
              kerberos_realm           => extlookup("kerberosRealm", $local_kerberos_realm) ,
              kdc_servers              => extlookup("kerberosKdcServers", $local_kdc_servers) ,
              admin_server             => extlookup("kerberosAdminServer", $local_admin_server) ,
    }

    class { 'kerberos::workstation::authconfig':
              stage                    => 'bootstrap' ,
    }

    class { 'ldapauth::client':
              base_dn                  => extlookup("baseDn", $local_ldap_auth_base_dn) ,
              ldap_servers             => extlookup("ldapServers", $local_ldap_auth_servers) ,
    }

    class { 'ssh::server::ldapauth':
              base_dn                  => extlookup("baseDn", $local_ldap_auth_base_dn) ,
              ldap_servers             => extlookup("ldapServers", $local_ldap_auth_servers),
              ldap_bind_user           => extlookup("ldapAuthBindUser", ['cn=Manager' , 'dc=hp' , 'dc=com' ]) ,
              ldap_bind_pw             => extlookup("ldapAuthBindPw", "Password1") ,
    }

    class { 'etc::nsswitch':
              nsswitch_passwd          => [ "files" , "sss" ] ,
              nsswitch_shadow          => [ "files" , "sss" ] , 
              nsswitch_group           => [ "files" , "sss" ] ,
              nsswitch_netgroup        => [ "files" , "sss" ] , 
              nsswitch_services        => [ "files" , "sss" ] ,
              nsswitch_automount       => [ "files" , "sss" , "ldap" ] , 
              nsswitch_sudoers         => [ "files" , "sss" ] , 
    }

    $local_filter_users = [ 'root' , 'master_admin' , 'ldap' , 'named' , 'avahi' , 'haldaemon' , 'dbus' , 'radiusd' , 'news' , 'nscd' ]

    class { 'sssd':
              filter_users             => unique(flatten([$env_bootstrap_admins, $local_filter_users])) ,
              base_dn                  => $local_ldap_auth_base_dn ,
              autofs_base_dn           => ['dc=hp', 'dc=com' ] ,
              sudo_base_dn             => ['ou=sudoers' , 'dc=hp' , 'dc=com' ] ,
              ldap_servers             => $local_ldap_auth_servers ,
              ldap_bind_user           => extlookup("ldapAuthBindUser", ['cn=Manager' , 'dc=hp' , 'dc=com' ]) ,
              ldap_bind_pw             => extlookup("ldapAuthBindPw", "Password1") ,
              ldap_access_filter       => extlookup("ldapAccessFilter", "memberOf=cn=cmxops_sssd,ou=groups,dc=hp,dc=com") ,
    }

    class { 'sssd::authconfig':
              stage                    => 'bootstrap' ,
    }

########################################################################
#
# AUTOFS
#
########################################################################  

    class { 'autofs':
             base_dn                  => $local_ldap_auth_base_dn ,
             ldap_servers             => $local_ldap_auth_servers ,
    }

########################################################################
#
# ROOT USER
#
########################################################################

    $root_enabled = [ 'dev' , ]

    if ($stack in $root_enabled or $nodetype == 'vta' ) {

        class { 'users::root': 
            stage          => 'bootstrap' ,

            root_password  => extlookup("rootPassword",'$yNcW1ThLynx!') ,
            root_shell     => extlookup("rootShell","/bin/bash") ,
        }
    }
    else {

        class { 'users::root':
            stage          => 'bootstrap' ,

            root_password  => extlookup("rootPassword",'$yNcW1ThLynx!') ,
            root_shell     => extlookup("rootShell","/sbin/nologin") ,
        }
    }
  
########################################################################
#
# LOCAL USERS
#
########################################################################

    class { 'users::cmxa': 
            cmxa_password   => extlookup("cmxaPassword",'$yNcW1ThLynx!') ,
    }

# The user lynxa is deprecated, we only manage for 
# existing dev and qa environments for now.  

    $lynxa_enabled = [ 'dev' , 'qa' , ]

    if $stack in $lynxa_enabled {

        class { 'users::lynxa': 
            lynxa_password  => extlookup("lynxaPassword",'$yNcW1ThLynx!') ,
        }
    }

#
# The user lynxe is given to groups other than us so restrict to dev only.
#
    $lynxe_enabled = [ 'dev' , ]

    if (lynxe_enabled and $hostname =~ /^a1-dev-...150$/) {
        class { 'users::lynxe': 
            lynxe_password  => extlookup("lynxePassword",'Prot3ctMyF1les!') ,
        }
    }

########################################################################
#
# SUDOERS
#
########################################################################

    class { 'etc::sudoers': 
            require_tty    => extlookup("sudoRequireTty", "yes") ,
            keep_java_home => extlookup("sudoKeepJavaHome", "yes") ,
    }

########################################################################
#
# NFS
#
########################################################################  
  
    class { 'nfs::common': }

########################################################################
#
# CLOUD INIT
#
########################################################################

    if ($platform == 'hpcloud') {

        class { 'cloud_init': }
    }

########################################################################
#
# COMMON SYSTEM UTILITIES
#
########################################################################

    class { 'sysutils::lsof': }

    class { 'sysutils::tcpdump': }

    class { 'sysutils::screen': }

    class { 'sysutils::sudo': }

    class { 'sysutils::htop': }

    class { 'sysutils::iotop': }

    class { 'sysutils::fping': }

    class { 'sysutils::wget': }

    class { 'sysutils::unzip': }

    class { 'deltarpm': }

    class { 'mailx': }

    class { 'mlocate': }

    class { 'mutt': }

########################################################################
#
# COMMON SYSTEM LIBRARIES (to keep updated)
#
########################################################################

    class { 'glibc': }

########################################################################
#
# MESSAGE OF THE DAY
#
########################################################################

    class { 'etc::motd': }

########################################################################
#
# CUSTOM /etc/rc.local SCRIPT
#
########################################################################

    class { 'etc::rc_local': 
            rclocal_file               => extlookup("rclocalFile", "") ,
    }

########################################################################
#
# CIS & RELATED SECURITY / AUDIT CLASSES
#
########################################################################

    class { 'abrt': }

    class { 'cis': }

    class { 'audit': }

    class { 'logrotate': }

    class { 'prelink': }

    $deploy_aide = [ 'preprod' , 'production' ]

    if $stack in $deploy_aide {

        class { 'aide': 
            stage  => 'final' ,
        }
    }

########################################################################
#
# NAGIOS MONITORING
#
########################################################################

    $deploy_nagios = [ 'qa' , 'perf' , 'demo' , 'preprod' , 'production' ]

    if $stack in $deploy_nagios {

        class { 'nagios::host': }

        class { 'nagios::plugins': }

        class { 'nagios::nrpe':
                fw_interface           => extlookup("nrpeFirewallInterface", $env_def_fw_interface) ,
                allowed_hosts          => $monitoring_host ,
        }
    }

########################################################################
#
# GANGLIA MONITORING
#
########################################################################

    $deploy_ganglia = [ 'dev' , 'qa' , 'perf' , 'demo' , 'preprod' , 'production' ]

    if $stack in $deploy_ganglia {


        class { 'ganglia::client':
                fw_interface         => extlookup("gangliaFirewallInterface", $env_def_fw_interface) ,
                cluster_master       => $monitoring_host ,
        }
    }
}
