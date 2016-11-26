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
}
