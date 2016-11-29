# Class: mesos::master
#
# This module manages Mesos master - installs Mesos package
# and starts master service.
#
# Sample Usage:
#
# class{ 'mesos::master': }
#
# Parameters:
#
#  [*single_role*]
#    Currently Mesos packages ships with both mesos-master and mesos-slave
#    enabled by default. `single_role` assumes that you use only either of
#    those on one machine. Default: true (mesos-slave service will be
#    disabled on master node)
#
#
# mesos-master service stores configuration in /etc/default/mesos-master in file/directory
# structure. Arguments passed via $options hash are converted to file/directories
#
class mesos::master(
  $enable           = true,
  $cluster          = 'mesos',
  $conf_dir         = '/etc/mesos-master',
  $work_dir         = '/var/lib/mesos', # registrar directory, since 0.19
  $conf_file        = '/etc/default/mesos-master',
  $acls_file        = '/etc/mesos/acls',
  $credentials_file = '/etc/mesos/master-credentials',
  $master_port      = $mesos::master_port,
  $zookeeper        = $mesos::zookeeper,
  $zk_path          = $mesos::zk_path,
  $zk_default_port  = $mesos::zk_default_port,
  $owner            = $mesos::owner,
  $group            = $mesos::group,
  $listen_address   = $mesos::listen_address,
  $manage_service   = $mesos::manage_service,
  $env_var          = {},
  $options          = {},
  $acls             = {},
  $credentials      = [],
  $syslog_logger    = true,
  $force_provider   = undef, #temporary workaround for starting services
  $use_hiera        = $mesos::use_hiera,
  $single_role      = $mesos::single_role,
  $node_number      = $mesos::params::def_node_number,
  $zk_id            = $mesos::params::def_zk_id,
  $quorum           = $mesos::params::def_quorum,
  $zoo_cfg          = $mesos::params::def_zoo_cfg,
  $zk               = $mesos::params::def_zk,
) inherits mesos {

  include mesos::params

  validate_hash($env_var)
  validate_hash($options)
  validate_hash($acls)
  validate_absolute_path($acls_file)
  validate_array($credentials)
  validate_absolute_path($credentials_file)
  validate_bool($manage_service)
  validate_bool($syslog_logger)
  validate_bool($single_role)

  # Install Zookeeper

  package { 'mesosphere-zookeeper':
    ensure  => latest ,
    require => [ Yumrepo['CentOS-Third-Party'] ,
       Class['oracle_java'] , ] ,
  }

  # Install Marathon
  package { 'marathon':
    ensure  => latest ,
    require => Yumrepo['CentOS-Third-Party'] ,
  }

  #
  # Configure Zookeeper
  #

  # Edit /etc/mesos/zk and replace existing entry with zk://<Mesos-node-Hostname/IP>:2181/mesos
  # Example 1 - zk://<zookeeper01.fqdn>:2181, <zookeeper02.fqdn>:2181,…/mesos
  # Example 2 - zk://a1-dev-mem001.lab.lynx-connected.com:2181/mesos
  #This is taken care by the mesos-deric module itself where zookeeper - Array of ZooKeeper servers (with port) which is used for slaves connecting to the master and also for leader election, e.g.:
  #single ZooKeeper: 127.0.0.1:2181 (which isn't fault tolerant)
  #multiple ZooKeepers: [ '192.168.1.1:2181', '192.168.1.2:2181', '192.168.1.3:2181'] (usually 3 or 5 ZooKeepers should be enough)
  #ZooKeeper URL will be stored in /etc/mesos/zk, /etc/default/mesos-master and/or /etc/default/mesos-slave

  # Set /var/lib/zookeeper/myid to a unique integer between 1 and 255 on each node (if you have more than 1 Mesos master)

  file { '/var/lib/zookeeper':
    ensure  => directory,
  }

  file { '/var/lib/zookeeper/myid':
    ensure  => present,
    content => "$zk_id\n",
    require => File["/var/lib/zookeeper"],
  }

  # Server Addresses - Append master server(s) IP to /etc/zookeeper/zoo.cfg on each node
  # server.x=<ip/fqdn of each mesos-master server>:2888:3888
  # Example - server.1=a1-dev-mem001.lab.lynx-connected.com:2888:3888

  if ($zoo_cfg == []) {
    $_zoo_cfgs = $mesos::params::def_zoo_cfg
  }
  elsif (is_array($zoo_cfg)) {
    $_zoo_cfgs = $zoo_cfg
  }
  else {
    $_zoo_cfgs = [ $zoo_cfg ,]
  }

  notify{"zoo conf value is $_zoo_cfgs":}

  $mod_name        = "${mesos::params::module_name}"
  $zoo_cfg_tpl  = "${mesos::params::zoo_conf}"
  $zoo_conf_tpl       = "$mod_name/$zoo_cfg_tpl"

  file { '/etc/zookeeper/zoo.cfg':
    ensure  => present,
    content => template("${$zoo_conf_tpl}"),
    mode    => '0644',
  }

  exec { "Start zookeeper":
    command     => "systemctl start zookeeper" ,
    path        => [ '/bin' , '/usr/bin' , '/usr/sbin' , '/usr/lib/systemd/system', ] ,
    logoutput   => true ,
    onlyif      => ["test -e /usr/lib/systemd/system/zookeeper.service", ] ,
  }

  exec { "Enable zookeeper":
    command     => "systemctl enable zookeeper" ,
    path        => [ '/bin' , '/usr/bin' , '/usr/sbin' , '/usr/lib/systemd/system', ] ,
    logoutput   => true ,
    onlyif      => ["test -e /usr/lib/systemd/system/zookeeper.service", ] ,
  }

  #
  # Configure Mesos Master
  #

  # Create/Edit /etc/mesos-master/cluster and your cluster name.
  # <desired name of mesos cluster> Example: Dev_001_Mesos

  file { '/etc/mesos-master/cluster':
    ensure  => present,
    content => "${node_number}\n",
  }

  # Create/Edit /etc/mesos-master/hostname and set Mesos Master's hostname
  # <resolvable FQDN of host> Example: a1-dev-mem001.lab.lynx-connected.com

  file { '/etc/mesos-master/hostname':
    ensure  => present,
    content => "${::fqdn}\n",
  }

  # Create/Edit /etc/mesos-master/ip and set Mesos Master's IP
  # <IP of host> Example: 16.73.18.01

  file { '/etc/mesos-master/ip':
    ensure  => present,
    content => "${::ipaddress}\n",
  }

  # Create/Edit /etc/mesos-master/quorum and set number of masters needed to determine leader.  Must be 51%+ of the number of masters. Minimum 3 masters required for any HA
  # 1 master, quorum = 1
  # 2 masters, quorum = 2
  # 3 masters, quorum = 2

  #file { '/etc/mesos-master/quorum':
  #  ensure  => present,
  #  content => "$quorum\n",
  #}

  #
  # Configure Marathon
  #

  # Create Marathon configuration folder

  file { '/etc/marathon':
    ensure  => directory,
  }

  file { '/etc/marathon/conf':
    ensure  => directory,
    require => File["/etc/marathon"],
  }

  # Copy Mesos Master Hostname information to Marathon
  file { '/etc/marathon/conf/hostname':
    ensure  => present,
    content => "${::fqdn}\n",
    require => File["/etc/marathon/conf"],
  }

  # Copy Zookeeper Mesos configuration to Marathon
  file { '/etc/marathon/conf/master':
    ensure  => present,
    content => "zk://${::fqdn}:2181/mesos\n",
    require => File["/etc/marathon/conf"],
  }

  file { '/etc/marathon/conf/zk':
    ensure  => present,
    content => "zk://${::fqdn}:2181/mesos\n",
    require => File["/etc/marathon/conf"],
  }

  # Stop Iptables or manually create required rules
  exec { "Stop iptables in master":
    command     => "systemctl stop iptables" ,
    path        => [ '/bin' , '/sbin' , '/usr/bin' , '/usr/sbin' , ] ,
    logoutput   => true ,
  }

  # Start Marathon

  exec { "Restart marathon":
    command     => "systemctl restart marathon" ,
    path        => [ '/bin' , '/sbin' , '/usr/bin' , '/usr/sbin' , ] ,
    logoutput   => true ,
  }

  if (!empty($acls)) {
    $acls_options = {'acls' => $acls_file}
    $acls_content = inline_template("<%= require 'json'; @acls.to_json %>")
    $acls_ensure = file
  } else {
    $acls_options = {}
    $acls_content = undef
    $acls_ensure = absent
  }

  if (!empty($credentials)) {
    $credentials_options = {'credentials' => "file://${credentials_file}"}
    $credentials_content = inline_template("<%= require 'json'; {:credentials => @credentials}.to_json %>")
    $credentials_ensure = file
  } else {
    $credentials_options = {}
    $credentials_content = undef
    $credentials_ensure = absent
  }

  if $use_hiera {
    # In Puppet 3 automatic lookup won't merge options across multiple config
    # files, see https://www.devco.net/archives/2016/02/03/puppet-4-data-lookup-strategies.php
    $opts = hiera_hash('mesos::master::options', $options)
    $merged_options = merge($opts, $acls_options, $credentials_options)
  } else {
    $merged_options = merge($options, $acls_options, $credentials_options)
  }

  if !empty($zookeeper) {
    if is_string($zookeeper) {
      warning('\$zookeeper parameter should be an array of IP addresses, please update your configuration.')
    }
    $zookeeper_url = zookeeper_servers_url($zookeeper, $zk_path, $zk_default_port)
  }

  file { $conf_dir:
    ensure  => directory,
    owner   => $owner,
    group   => $group,
    recurse => true,
    purge   => true,
    force   => true,
    require => Class['::mesos::install'],
  }

  file { $work_dir:
    ensure => directory,
    owner  => $owner,
    group  => $group,
  }

  file { $acls_file:
    ensure  => $acls_ensure,
    content => $acls_content,
    owner   => $owner,
    group   => $group,
    mode    => '0444',
  }

  file { $credentials_file:
    ensure  => $credentials_ensure,
    content => $credentials_content,
    owner   => $owner,
    group   => $group,
    mode    => '0400',
  }

  # work_dir can't be specified via options,
  # we would get a duplicate declaration error
  mesos::property {'master_work_dir':
    value  => $work_dir,
    dir    => $conf_dir,
    file   => 'work_dir',
    owner  => $owner,
    group  => $group,
    notify => Service['mesos-master'],
  }

  create_resources(mesos::property,
    mesos_hash_parser($merged_options, 'master'),
    {
      dir    => $conf_dir,
      owner  => $owner,
      group  => $group,
      notify => Service['mesos-master'],
    }
  )

  file { $conf_file:
    ensure  => present,
    content => template('mesos/master.erb'),
    owner   => $owner,
    group   => $group,
    mode    => '0644',
    require => [File[$conf_dir], Package['mesos']],
  }

  # When launched by the "mesos-init-wrapper", the Mesos service's stdout/stderr
  # are logged to syslog using logger (http://linux.die.net/man/1/logger). This
  # is disabled using the "--no-logger" flag. There is no equivalent "--logger"
  # flag so the option must either be present or completely removed.
  $logger_ensure = $syslog_logger ? {
    true  => absent,
    false => present,
  }
  mesos::property { 'master_logger':
    ensure => $logger_ensure,
    file   => 'logger',
    value  => false,
    dir    => $conf_dir,
    owner  => $owner,
    group  => $group,
  }

  # Install mesos-master service
  mesos::service { 'master':
    enable         => $enable,
    force_provider => $force_provider,
    manage         => $manage_service,
    subscribe      => File[$conf_file],
  }

  if (!defined(Class['mesos::slave']) and $single_role) {
    mesos::service { 'slave':
      enable => false,
      manage => $manage_service,
    }
  }
}
