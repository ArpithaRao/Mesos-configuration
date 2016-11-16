########################################################################
# mesos-master
#
# Application server running Mesos
########################################################################

node 'mesos-master' inherits 'base' {

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
}else{
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
  # MESOS MASTER
  #
  ########################################################################

  #Add the repo
#  exec { "Add mesos repository":
#    command     => "rpm -Uvh http://repos.mesosphere.com/el/7/noarch/RPMS/mesosphere-el-repo-7-1.noarch.rpm" ,
#    alias       => 'add-mesos-repo' ,
#    path        => [ '/bin' , '/usr/bin' , '/usr/sbin' , '/usr/lib/systemd/system', ] ,
#    logoutput   => true ,
#    onlyif      => ["test ! -e /usr/lib/systemd/system/mesos-master.service", ] ,
#    require => Class['oracle_java'] ,
#  }

  # Update node
#  exec { "Yum update node":
#    command     => "yum list updates && yum update -y && yum clean all" ,
#    alias       => 'yum-update-node' ,
#    path        => [ '/bin' , '/usr/bin' , '/usr/sbin' , '/usr/lib/systemd/system', ] ,
#    logoutput   => true ,
#    onlyif      => ["test ! -e /usr/lib/systemd/system/mesos-master.service", ] ,
#  }

  class{'mesos':
    repo => 'mesosphere',
    zookeeper => [ extlookup("zookeeper", "")],
  }

  class{ 'mesos::master':

    work_dir         => '/var/lib/mesos',
    node_number      => extlookup("mesosClusterName", "") ,
    zk_id            => extlookup("zookeeperMyId", "") ,
    #quorum           => extlookup("quorumMembers", "") ,
    zk               => extlookup("zookeeper_uri", "") ,
    zoo_cfg          => extlookup("zoo_cfg",""),
    options => {
      quorum   => extlookup("quorumMembers", "") ,
    }
  }
}
