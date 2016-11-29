# Class: mesos::firewall
# This module configures firewall for mesos-slave
#
class mesos::firewall (  $fw_interface = '' , ) {

  if ($fw_interface == '') {
    $_fw_interface = $mesos::params::def_fw_interface
  }
  else {
    $_fw_interface = $fw_interface
  }

  firewall { '125 allow mesos-slave':
    state    => [ 'NEW' , ] ,
    dport    => 5051 ,
    proto    => 'tcp' ,
    iniface  => "${_fw_interface}" ,
    action   => 'accept' ,
  }

  # firewall { '126 allow mesos-master':
  #   state    => [ 'NEW' , ] ,
  #   dport    => 5050 ,
  #   proto    => 'tcp' ,
  #   iniface  => "${_fw_interface}" ,
  #   action   => 'accept' ,
  # }

  firewall { '8080 port unblocked for mesos on http':
    state    => [ 'NEW' , ] ,
    dport    => 8080 ,
    proto    => 'tcp' ,
    iniface  => "${_fw_interface}" ,
    action   => 'accept' ,
  }

  firewall { '8443 port unblocked for mesos on https':
    state    => [ 'NEW' , ] ,
    dport    => 8443 ,
    proto    => 'tcp' ,
    iniface  => "${_fw_interface}" ,
    action   => 'accept' ,
  }

  firewall { '004 accept all outgoing rules':
    chain    => 'OUTPUT',
    proto    => 'all',
    action   => 'accept',
  }

  firewall { '005 accept all incoming rules':
    chain    => 'INPUT',
    proto    => 'all',
    action   => 'accept',
  }
}

##Firewall rule for allowing all docker connections on slaves if iptables is enables.
##iptables -A INPUT -s 172.17.0.0/16 -i docker0 -p tcp -j ACCEPT
