########################################################################
# mesos-slave
#
# Application server running Mesos slave
########################################################################

node 'mesos-slave' inherits 'base' {

  ########################################################################
  #
  # PUPPET
  #
  ########################################################################

  class { 'puppet::agent':
    puppet_master           => extlookup("puppetMaster", $env_puppet_master) ,
    puppet_runinterval      => extlookup("puppetRunInterval", $env_puppet_runinterval) ,
    puppet_enabled          => extlookup("puppetEnabled", $env_puppet_enabled) ,
    puppet_service          => extlookup("puppetService", $env_puppet_service) ,
  }

 
  ########################################################################
  #
  # SYSTEM SERVICES
  #
  ########################################################################

  class { 'monit':
    fw_interface              => extlookup("monitFirewallInterface", $env_def_fw_interface) ,
    refresh_interval          => extlookup("monitRefreshIntervalSeconds", "60") ,
  }

  class { 'ntp::client':
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

  class { 'rsyslog::client':
    rsyslog_server                  => $syslog_hosts ,
    system_log_rate_limit_interval  => extlookup("systemLogRateLimitInterval" , "") ,
    system_log_rate_limit_burst     => extlookup("systemLogRateLimitBurst" , "") ,
  }


  ########################################################################
  #
  # ORACLE JAVA
  #
  ########################################################################

  $set_default_java_jre = extlookup("jreSetDefaultJava", "")
  $set_default_java_jdk = extlookup("jdkSetDefaultJava", "")

  if($set_default_java_jre == "true" and $set_default_java_jdk == "true"){
    warning("Both jre and jdk has been set as default. Make sure only one is default.")
  }

  if($set_default_java_jdk == "true"){
    $default_java = extlookup("jdkJavaHome", $env_jdk_java_home)
  } else{
    $default_java = extlookup("jreJavaHome", $env_jre_java_home)
  }
  class { 'oracle_java':
    pkg_version             => extlookup("jrePkgVersion", $env_jre_pkg_version) ,
    java_home               => extlookup("jreJavaHome", $env_jre_java_home) ,
    set_default_java        => $set_default_java_jre ,
  }

  class { 'oracle_java::jceunlimited':
    java_home               => extlookup("jreJavaHome", $env_jre_java_home) ,

  }

  class { 'oracle_java::jdk':
    pkg_version             => extlookup("jdkPkgVersion", $env_jdk_pkg_version) ,
    java_home               => extlookup("jdkJavaHome", $env_jdk_java_home) ,
    set_default_java        => $set_default_java_jdk ,
  }

  class { 'oracle_java::jdk::jceunlimited':
    java_home               => extlookup("jdkJavaHome", $env_jdk_java_home) ,

  }

 
  ########################################################################
  #
  # MESOS SLAVE
  #
  ########################################################################

  #
  # Install and configure Docker, is handled by Docker Module
  #

  $deploy_docker = [ 'dev' , 'qa' , 'preprod', 'prod' , 'production' ]

  $dockerRepoUrl = $stack ? {
    default     => extlookup("dockerRepo", "https://yum.dockerproject.org/repo/main/centos/7/") ,
    dev         => extlookup("dockerRepo", "https://yum.dockerproject.org/repo/main/centos/7/") ,
    qa          => extlookup("dockerRepo", "https://yum.dockerproject.org/repo/main/centos/7/") ,
    integration => "https://yum.dockerproject.org/repo/main/centos/7/" ,
    test1       => "https://yum.dockerproject.org/repo/main/centos/7/" ,
    test2       => "https://yum.dockerproject.org/repo/main/centos/7/" ,
    sandbox     => "https://yum.dockerproject.org/repo/main/centos/7/" ,
    preprod     => "https://yum.dockerproject.org/repo/main/centos/7/" ,
    production  => "https://yum.dockerproject.org/repo/main/centos/7/" ,
    performance => "https://yum.dockerproject.org/repo/main/centos/7/" ,
    demo        => "https://yum.dockerproject.org/repo/main/centos/7/" ,
  }

  if $stack in $deploy_docker {
    $artifactory_url = extlookup("artifactoryUrl", "")
    $artifactory_username = extlookup("artifactoryUserName", "")
    $artifactory_password = extlookup("artifactoryPassword", "")
    $artifactory_email = extlookup("artifactoryEmail", "")
    $docker_image = extlookup("dockerImage", "")
    $is_registry_secured = extlookup("secureRegistry", "no")
    $is_storage_setup = extlookup("storageSetUp", "no")

    if ($artifactory_url == 'undef' or $artifactory_url == '') {
      fail("No parameter was passed in for artifactoryUrl, cannot continue.  artifactoryUrl has to be configured for Mesos Slave.")
    } else {
      $_artifactory_url = "--insecure-registry $artifactory_url:8444"
    }

    if ($artifactory_username == 'undef' or $artifactory_username == '') {
      fail("No parameter was passed in for artifactoryUserName, cannot continue.  artifactoryUserName has to be configured for Mesos Slave.")
    } else {
      $_artifactory_username = $artifactory_username
    }

    if ($artifactory_password == 'undef' or $artifactory_password == '') {
      fail("No parameter was passed in for artifactoryPassword, cannot continue.  artifactoryPassword has to be configured for Mesos Slave.")
    } else {
      $_artifactory_password = $artifactory_password
    }

    if ($artifactory_email == 'undef' or $artifactory_email == '') {
      fail("No parameter was passed in for artifactoryEmail, cannot continue.  artifactoryEmail has to be configured for Mesos Slave.")
    } else {
      $_artifactory_email = $artifactory_email
    }

    if ($docker_image == 'undef' or $docker_image == '') {
      fail("No parameter was passed in for dockerImage, cannot continue.  dockerImage has to be configured for Mesos Slave.")
    } else {
      $_docker_image = $docker_image
    }

    if ($is_registry_secured == 'undef' or $is_storage_setup == 'undef' or $artifactory_url == '') {
      fail("No parameter was passed in for secureRegistry or starageSetUp, cannot continue. They should to be configured for Mesos slave.")
    }

    if ($is_registry_secured == 'no' and $is_storage_setup == 'no') {
      # To setup and install Docker
      class { 'docker':
        version          => '1.9.1-1.el7.centos',
        dns              => ['16.73.20.123' , '16.73.20.124' , '8.8.8.8'],
        extra_parameters => ["--insecure-registry ${artifactory_url}:8442", "--insecure-registry $artifactory_url:8443", $_artifactory_url, "--insecure-registry $artifactory_url:8445",  "-H tcp://0.0.0.0:2375", ],
      }
    } elsif ($is_registry_secured == 'no' and $is_storage_setup == 'yes') {
      # To setup and install Docker
      class { 'docker':
        version          => '1.9.1-1.el7.centos',
        dns              => [ '16.73.20.123' , '16.73.20.124' , '8.8.8.8'],
        extra_parameters => ["--insecure-registry $artifactory_url:8442", "--insecure-registry $artifactory_url:8443", "--insecure-registry $artifactory_url:8445",  "--storage-driver=devicemapper", "--storage-opt=dm.thinpooldev=/dev/mapper/docker-thinpool" , "--storage-opt dm.use_deferred_removal=true", $_artifactory_url],
      }
    }
    else {
      class { 'docker':
        version          => '1.9.1-1.el7.centos',
        dns              => [ '16.73.20.123' , '16.73.20.124' , '8.8.8.8'],
      }
    }

    #Add mesos repo
#    exec { "Add mesos repository":
#      command     => "rpm -Uvh http://repos.mesosphere.com/el/7/noarch/RPMS/mesosphere-el-repo-7-1.noarch.rpm" ,
#      alias       => 'add-mesos-repo' ,
#      path        => [ '/bin' , '/usr/bin' , '/usr/sbin' , '/usr/lib/systemd/system', ] ,
#      logoutput   => true ,
#      onlyif      => ["test ! -e /usr/lib/systemd/system/mesos-slave.service", ] ,
#      require => Class['oracle_java'] ,
#    }

    # Update node
  exec { "Yum update node":
    command     => "yum list updates && yum update -y && yum clean all" ,
    alias       => 'yum-update-node' ,
    path        => [ '/bin' , '/usr/bin' , '/usr/sbin' , '/usr/lib/systemd/system', ] ,
    logoutput   => true ,
    onlyif      => ["test ! -e /usr/lib/systemd/system/mesos-slave.service", ] ,
  }
    class{'mesos':
      repo => 'mesosphere',
      zookeeper => [ extlookup("zookeeper", "")],
    }

    class{ 'mesos::slave':
      master                        => extlookup("masterNodeIp", $mesos::params::def_master),
      master_fqdn                   => extlookup("masterNodeFqdn", $mesos::params::def_master_fqdn),
      attribute                     => extlookup("mesosSlaveAttributes", $mesos::params::def_attribute),
      containerizers                => extlookup("containerizers", $mesos::params::def_containerizers),
      executor_registration_timeout => extlookup("executor_registration_timeout", $mesos::params::def_executor_registration_timeout),
      gc_delay                      => extlookup("gc_delay", $mesos::params::def_gc_delay),
      gc_disk_headroom              => extlookup("gc_disk_headroom", $mesos::params::def_gc_disk_headroom),
      launcher_dir                  => extlookup("launcher_dir", $mesos::params::def_launcher_dir),
      resource                      => extlookup("resource", $mesos::params::def_resource),
      artifactory_url               => extlookup("artifactoryUrl",$mesos::params::def_artifactory_url),
      artifactory_username          => extlookup("artifactoryUserName",$mesos::params::def_artifactory_username),
      artifactory_password          => extlookup("artifactoryPassword",$mesos::params::def_artifactory_password),
      artifactory_email             => extlookup("artifactoryEmail",$mesos::params::def_artifactory_email),
      fw_interface                  => $mesos::params::def_fw_interface ,
      zk                            => extlookup("zookeeper", "") ,
    }
  }
}
