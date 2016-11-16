########################################################################
# puppet-master
#
# Puppet Master
#
# This manifest is intended for a puppet master that does not 
# perform any other roles in the environment (i.e. certificate master,
# package repository, or puppetdb server)
########################################################################

node 'puppet-master' inherits 'base' {
 
########################################################################
#
# YUM REPOSITORIES
#
########################################################################

  $passengerRepoUrl = $stack ? {
    default     => extlookup("passengerPrivateRepoUrl", "https://${yum_package_host}/passenger/unstable/x86_64/") ,
    dev         => extlookup("passengerPrivateRepoUrl", "https://${yum_package_host}/passenger/unstable/x86_64/") ,
    qa          => extlookup("passengerPrivateRepoUrl", "https://${yum_package_host}/passenger/unstable/x86_64/") ,
    integration => "https://${yum_package_host}/passenger/stable/x86_64/" ,
    test1       => "https://${yum_package_host}/passenger/stable/x86_64/" ,
    test2       => "https://${yum_package_host}/passenger/stable/x86_64/" ,
    sandbox     => "https://${yum_package_host}/passenger/stable/x86_64/" ,
    preprod     => "https://${yum_package_host}/passenger/stable/" ,
    production  => "https://${yum_package_host}/passenger/stable/" ,
    performance => "https://${yum_package_host}/passenger/stable/x86_64/" ,
    demo        => "https://${yum_package_host}/passenger/unstable/" ,
  }

  class { 'repo::passengerprivate':
            baseurl         => extlookup("passengerPrivateRepoUrl", $passengerRepoUrl) ,
            enabled         => extlookup("passengerPrivateRepoEnabled", "1") ,
            gpgcheck        => extlookup("passengerPrivateRepoGpgcheck", "0") ,
            metadata_expire => extlookup("passengerPrivateRepoMetadataExpire", "60m") ,

            sslverify       => 'False' ,
  }

########################################################################
#
# SYSTEM SERVICES
#
########################################################################

    class { 'ntp::client':
              fw_interface                    => extlookup("ntpFirewallInterface", $env_def_fw_interface) ,
              ntp_servers                     => $local_ntp_servers ,
    }

    class { 'ssh::client':
              strict_key_checking             => 'no' ,
    }

    class { 'ssh::server':
              fw_interface                    => extlookup("sshFirewallInterface", $env_def_fw_interface) ,
              allowed_groups                  => extlookup("sshAllowedGroups", $ssh_allowed_groups) ,
              client_alive_interval           => extlookup("sshClientAliveInterval", '300') ,
              client_alive_count_max          => extlookup("sshClientAliveCount", '0') ,
              password_authentication         => extlookup("sshPasswordAuthentication", 'no') ,
              permit_root_login               => extlookup("sshPermitRootLogin", 'no') ,
              x11_forwarding                  => extlookup("sshX11Forwarding", 'no') ,
              tcp_forwarding                  => extlookup("sshTcpForwarding", 'no') ,
              ssh_ldap_auth                   => extlookup("sshLdapAuth", 'yes') ,
    }

    class { 'postfix':
              postfix_relay_domains           => $local_dns_domain ,
              postfix_relayhost               => $smtp_relay_host ,
              root_email                      => $admin_email_address ,
    }

    class { 'rsyslog::client':
              rsyslog_server                  => $syslog_hosts ,
              system_log_rate_limit_interval  => extlookup("systemLogRateLimitInterval" , "") ,
              system_log_rate_limit_burst     => extlookup("systemLogRateLimitBurst" , "") ,
    }

########################################################################
#
# SECURITY CONFIGURATION
#
# Since this node type does not require a graphical user interface,
# we add additional Center for Internet Security (CIS) security
# configuration to enforce that state.   
#
########################################################################

    class { 'cis::nogui': }

########################################################################
#
# SSL
#
########################################################################

    if $env_ssl_mode == 'certmaster' {

        class { 'func::minion': }

        class { 'certmaster::minion':
                  certmaster          => $puppet_master ,
        }

        class { 'certmonger': }
    }
    elsif $env_ssl_mode == 'wildcard' {

        class { 'sslcert::wildcard': }
    }
    else {
    }

########################################################################
#
# ANTIVIRUS & HOST INTRUSION PREVENTION
#
########################################################################

    $deploy_mcafee = [ 'preprod' , 'production' ]

    if $stack in $deploy_mcafee {

        class { 'mcafee::vse': }
    }

########################################################################
#
# SYSTEM PERFORMANCE TUNING
#
########################################################################

    class { 'etc::sysctl':
                  vm_swappiness           => extlookup("vmSwappiness", "0") ,
                  fs_file_max             => extlookup("fsFileMax", "999999") ,
    }

########################################################################
#
# APACHE & PASSENGER
#
########################################################################

    class { 'apache':
                fw_interface        => extlookup("apacheFirewallInterface", $env_def_fw_interface) ,
                apache_http         => extlookup("apacheHttp", "") ,
                apache_https        => extlookup("apacheHttps", "") ,
                servername          => extlookup("servername", "") ,
                serveradmin         => $admin_email_address ,
                use_canonicalname   => extlookup("useCanonicalName", "") ,
                docroot             => extlookup("docRoot", "") ,
                ssl_cert_file       => extlookup("sslCertFile", "") ,
                ssl_key_file        => extlookup("sslKeyFile", "") ,
    }

    case $::operatingsystem {

        centos, redhat: {

            case $::operatingsystemmajrelease {

                6: {
                    class { 'apache::mod_passenger': }
                }

                7: {
                    class { 'apache::mod_passenger': }
                    class { 'apache::devel': }
                    class { 'ruby::devel': }
                    class { 'ruby::rubygems': }
                    class { 'gcc::cplusplus': }
                    class { 'curl::devel': }
                    class { 'zlib::devel': }
                    class { 'make': }
                    class { 'automake': }
                    class { 'openssl::devel': }
                }
            }
        }
    }

########################################################################
#
# PHPPGADMIN
#
# phpPgAdmin can make it easier to look at or manipulate data in 
# the database.
#
########################################################################

    $deploy_phppgadmin = [ 'dev' , 'qa' , 'perf' , 'preprod' , 'production' , ]

    if $stack in $deploy_phppgadmin {

        class { 'phppgadmin':
                pgadmin_user        => extlookup("pgAdminUser", "") ,
                pgadmin_pass        => extlookup("pgAdminPass", "") ,
                pg_mode             => 'standalone' ,
        }
    }

########################################################################
#
# POSTGRESQL SERVER
#
########################################################################

    class { 'postgres::standalone':
                 fw_interface           => extlookup("pgFirewallInterface", $env_def_fw_interface) ,
                 pg_allowedhosts        => extlookup("allowedHosts", []) ,
                 max_connections        => extlookup("maxConnections", "200") ,
                 pg_pass                => extlookup("pgPass", "") ,
    }

########################################################################
#   
# MYSQL SERVER
#   
########################################################################

    case $::operatingsystem {

        centos, redhat: {

            case $::operatingsystemmajrelease {

                6: {

                    class { 'mysql::standalone':
                        fw_interface            => extlookup("mysqlFirewallInterface", $env_def_fw_interface) ,
                        mysql_version           => extlookup("mysqlversion", "5.6") ,
                        mysql_root_password     => extlookup("mysqlRootPassword", "") ,
                    }
                }
            }
        }
    }

########################################################################
#   
# MCOLLECTIVE
#   
########################################################################

    class { 'mcollective::client':
                pool_hosts              => extlookup("mcollectivePoolHosts", $env_mco_pool_hosts) ,
                connector_type          => extlookup("mcollectiveConnectorType", "rabbitmq") ,
                mq_port                 => extlookup("mqPort", "") ,
                mq_user                 => extlookup("mqUser", $env_mco_user) ,
                mq_password             => extlookup("mqPassword", $env_mco_password) ,
                vhost                   => extlookup("mcoVhost", "") ,
                security_provider       => extlookup("securityProvider", "") ,
                mco_psk                 => extlookup("mcoPsk", $env_mco_psk) ,
    }

    case $::operatingsystem {

        centos, redhat: {

            case $::operatingsystemmajrelease {

                6: {
                    class { 'mcollective::facter': }
                }
            }
        }
    }

    class { 'mcollective::filemgr::client': }

    class { 'mcollective::iptables::client': }

    class { 'mcollective::nettest::client': }

    class { 'mcollective::nrpe::client': }

    class { 'mcollective::puppet::client': }

    class { 'mcollective::package::client': }

    class { 'mcollective::service::client': }

    class { 'mcollective::shell::client': }


########################################################################
#
# PUPPET , PUPPET DASHBOARD , & PUPPETDB
#
########################################################################

    class { 'puppet::master':
                fw_interface            => extlookup("puppetMasterFirewallInterface", $env_def_fw_interface) ,
                master_dns_alt_names    => extlookup("puppetMasterDnsAltNames", "") ,
                autosign_hosts          => extlookup("puppetMasterAutosignHosts", []) ,
                configure_foreman       => extlookup("configureForeman", false),
                configure_tagmail       => extlookup("configureTagmail", false),
                foreman_url             => extlookup("foremanUrl", ''),
                tagmail_email           => extlookup("tagmailEmail", ''),
                tagmail_smtp            => extlookup("smtpServer", ''),
    }

    class { 'puppetdb':
                fw_interface            => extlookup("puppetdbFirewallInterface", $env_def_fw_interface) ,
                db_password             => extlookup("puppetdbPassword", "") ,
                node_ttl                => extlookup("puppetdbNodeTtl", "") ,
                node_purge_ttl          => extlookup("puppetdbNodePurgeTtl", "") ,
                report_ttl              => extlookup("puppetdbReportTtl", "") ,
    }

    case $::operatingsystem {

        centos, redhat: {

            case $::operatingsystemmajrelease {

                6: {
                    class { 'puppet::dashboard':
                        stage                   => 'final' ,
                        mysql_root_password     => extlookup("mysqlRootPassword", "") ,
                        mysql_mode              => 'standalone' ,
                        dashboard_user          => extlookup("dashboardUser", "") ,
                        dashboard_pass          => extlookup("dashboardPass", "") ,
                    }
                }
            }
        }
    }

########################################################################
#
# SUBVERSION SERVER
#
########################################################################

    class { 'subversion': }

########################################################################
#
# ORACLE JAVA
#
########################################################################

   class { 'oracle_java':
                  pkg_version             => extlookup("jrePkgVersion", $env_jre_pkg_version) ,
                  java_home               => extlookup("jreJavaHome", $env_jre_java_home) ,
                  set_default_java        => extlookup("jreSetDefaultJava", "") ,
   }

   class { 'oracle_java::jceunlimited':
                  java_home               => extlookup("jreJavaHome", $env_jre_java_home) ,

   }

########################################################################
#
# LLAMASHELL
#
########################################################################
    $deploy_llamashell=[ 'dev', 'qa' ] 
    if $stack in $deploy_llamashell {

 class { 'llamashell':
            fw_interface            => extlookup("llamashellFirewallInterface", $env_def_fw_interface) ,
            llamashell_ssl          => extlookup("llamashellSsl", "false") ,
            llamashell_ssl_keypass  => extlookup("llamashellSslKeypass", "Password1") ,
            llamashell_client_ssl          => extlookup("llamashellClientSsl", "false") ,
            llamashell_client_ssl_keypass  => extlookup("llamashellClientSslKeypass", "Password1") ,
        }

    }
}
