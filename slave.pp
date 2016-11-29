# Class: mesos::slave
#
# This module manages Mesos slave
#
# Parameters:
#  [*enable*]
#    Install Mesos slave service (default: true)
#
#  [*master*]
#    IP address of Mesos master (default: localhost)
#
#  [*master_port*]
#    Mesos master's port (default 5050)
#
#  [*zookeeper*]
#    Zookeeper URL string (which keeps track of current Mesos master)
#
#  [*work_dir*]
#    Directory for storing task's temporary files (default: /tmp/mesos)
#
#  [*isolation*]
#    Isolation mechanism - either 'process' or 'cgroups' newer versions
#    of Mesos > 0.18 support isolation mechanism 'cgroups/cpu,cgroups/mem'
#    or posix/cpu,posix/mem
#
#  [*options*]
#    Any extra arguments that are not named here could be
#    stored in a hash:
#
#      options => { "key" => "value" }
#
#    (as value you can pass either string, boolean or numeric value)
#    which is serialized to disk and then passed to mesos-slave as:
#
#      --key=value
#
#  [*single_role*]
#    Currently Mesos packages ships with both mesos-master and mesos-slave
#    enabled by default. `single_role` assumes that you use only either of
#    those on one machine. Default: true (mesos-master service will be
#    disabled on slave node)
#
# Sample Usage:
#
# class{ 'mesos::slave':
#   master      => '10.0.0.1',
#   master_port => 5050,
# }
#

class mesos::slave (
  $enable           = true,
  $port             = 5051,
  $work_dir         = '/tmp/mesos',
  $checkpoint       = false,
  $isolation        = '',
  $conf_dir         = '/etc/mesos-slave',
  $conf_file        = '/etc/default/mesos-slave',
  $credentials_file = '/etc/mesos/slave-credentials',
  $master           = $mesos::params::def_master,
  $master_fqdn      = $mesos::params::def_master_fqdn,
  $master_port      = $mesos::master_port,
  $zookeeper        = $mesos::zookeeper,
  $zk_path          = $mesos::zk_path,
  $zk_default_port  = $mesos::zk_default_port,
  $owner            = $mesos::owner,
  $group            = $mesos::group,
  $listen_address   = $mesos::listen_address,
  $manage_service   = $mesos::manage_service,
  $env_var          = {},
  $cgroups          = {},
  $options          = {},
  $principal        = undef,
  $secret           = undef,
  $syslog_logger    = true,
  $force_provider   = undef, #temporary workaround for starting services
  $use_hiera        = $mesos::use_hiera,
  $single_role      = $mesos::single_role,
  $containerizers                 = $mesos::params::def_containerizers,
  $executor_registration_timeout  = $mesos::params::def_executor_registration_timeout,
  $gc_delay                       = $mesos::params::def_gc_delay,
  $gc_disk_headroom               = $mesos::params::def_gc_disk_headroom,
  $launcher_dir                   = $mesos::params::def_launcher_dir,
  $resource                       = $mesos::params::def_resource,
  $attribute                      = $mesos::params::def_attribute,
  $artifactory_url                = $mesos::params::def_artifactory_url,
  $artifactory_username           = $mesos::params::def_artifactory_username,
  $artifactory_password           = $mesos::params::def_artifactory_password,
  $artifactory_email              = $mesos::params::def_artifactory_email,
  $fw_interface                   = $mesos::params::def_fw_interface ,
  $zk                             = $mesos::params::def_zk,
  $is_version                     = undef,
) inherits mesos {

  include mesos::params

  $_fw_interface = $fw_interface

  validate_hash($env_var)
  validate_hash($cgroups)
  validate_hash($options)
  validate_string($isolation)
  validate_string($principal)
  validate_string($secret)
  validate_absolute_path($credentials_file)
  validate_bool($manage_service)
  validate_bool($syslog_logger)
  validate_bool($single_role)

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
    notify  => Service['mesos-slave'], # when key is removed we want to reload the service
  }

  # stores properties in file structure
  create_resources(mesos::property,
    mesos_hash_parser($cgroups, 'slave', 'cgroups'),
    {
      owner  => $owner,
      group  => $group,
      dir    => $conf_dir,
      notify => Service['mesos-slave'],
    }
  )

  # for backwards compatibility, prefered way is specification via $options
  if !empty($isolation) {
    $isolator_options = {'isolation' => $isolation}
  } else {
    $isolator_options = {}
  }

  if (!empty($principal) and !empty($secret)) {
    $credentials_options = {'credential' => $credentials_file}
    $credentials_content = "{\"principal\": \"${principal}\", \"secret\": \"${secret}\"}"
    $credentials_ensure = file
  } else {
    $credentials_options = {}
    $credentials_content = undef
    $credentials_ensure = absent
  }

  if $use_hiera {
    # In Puppet 3 automatic lookup won't merge options across multiple config
    # files, see https://www.devco.net/archives/2016/02/03/puppet-4-data-lookup-strategies.php
    $opts = hiera_hash('mesos::slave::options', $options)
    $merged_options = merge($opts, $isolator_options, $credentials_options)
  } else {
    $merged_options = merge($options, $isolator_options, $credentials_options)
  }

  # work_dir can't be specified via options,
  # we would get a duplicate declaration error
  mesos::property {'slave_work_dir':
    value  => $work_dir,
    dir    => $conf_dir,
    file   => 'work_dir',
    owner  => $owner,
    group  => $group,
    notify => Service['mesos-slave'],
  }

  file { $work_dir:
    ensure => directory,
    owner  => $owner,
    group  => $group,
  }

  file { $credentials_file:
    ensure  => $credentials_ensure,
    content => $credentials_content,
    owner   => $owner,
    group   => $group,
    mode    => '0400',
  }

  create_resources(mesos::property,
    mesos_hash_parser($merged_options, 'slave'),
    {
      dir    => $conf_dir,
      owner  => $owner,
      group  => $group,
      notify => Service['mesos-slave'],
    }
  )
  file { $conf_file:
    ensure  => 'present',
    content => template('mesos/slave.erb'),
    owner   => $owner,
    group   => $group,
    mode    => '0644',
    require => [Class['mesos::config'], File[$conf_dir], Package['mesos']],
  }

  $logger_ensure = $syslog_logger ? {
    true  => absent,
    false => present,
  }
  mesos::property { 'slave_logger':
    ensure => $logger_ensure,
    file   => 'logger',
    value  => false,
    dir    => $conf_dir,
    owner  => $owner,
    group  => $group,
  }

  # Install mesos-slave service
  mesos::service { 'slave':
    enable         => $enable,
    force_provider => $force_provider,
    manage         => $manage_service,
    subscribe      => File[$conf_file],
  }

  if (!defined(Class['mesos::master']) and $single_role) {
    mesos::service { 'master':
      enable => false,
      manage => $manage_service,
    }
  }

  #
  # Configure Mesos Slave
  #

  # For the section(s) below you can use any editor of your choice

  # Edit /etc/mesos/zk and replace existing entry with zk://<Mesos-MASTER-Hostname>:2181/mesos
  # Example 2 - zk://a1-dev-mem001.lab.lynx-connected.com:2181

  # Set the ipaddress
  file { '/etc/mesos-slave/ip':
    ensure  => present,
  }
  exec { "Add the node ip address to /etc/mesos-slave/ip":
    command     => "/sbin/ifconfig $_fw_interface | grep '\binet\b'  | awk '{print \$2}' | tee /etc/mesos-slave/ip" ,
    path        => [ '/bin' , '/sbin' , '/usr/bin' , '/usr/sbin' , ] ,
    logoutput   => true ,
    require => File["/etc/mesos-slave/ip"],
  }

  # Set the hostname
  file { '/etc/mesos-slave/hostname':
    ensure  => present,
    content => "${::fqdn}\n",
  }

  # Set the containerizers
  file { '/etc/mesos-slave/containerizers':
    ensure  => present,
    content => "$containerizers\n",
  }

  # Set the exectutor_registration_timeout
  file { '/etc/mesos-slave/executor_registration_timeout':
    ensure  => present,
    content => "$executor_registration_timeout\n",
  }

  # Set the attributes
  file { '/etc/mesos-slave/attributes':
    ensure  => present,
    content => "aspen-role:$attribute\n",
  }

  # Set gc_delay
  file { '/etc/mesos-slave/gc_delay':
    ensure  => present,
    content => "$gc_delay\n",
  }

  # Set gc_disk_headroom
  file { '/etc/mesos-slave/gc_disk_headroom':
    ensure  => present,
    content => "$gc_disk_headroom\n",
  }

  # Set launcher_dir
  file { '/etc/mesos-slave/launcher_dir':
    ensure  => present ,
    content => "$launcher_dir\n" ,
  }

  # Set resources (cpus: Total # of CPU - 1; ports:[7000-9050, 31000-59000]
  # NOTE - Number of CPUs below must be calculated as follows
  # cpus = Total # of CPU - 1

  file { '/etc/mesos-slave/resources':
    ensure  => present ,
    content => "$resource\n" ,
  }

  #Iptables has to be stopped on mesos-slave in order to be able to establish connections to postgres node
  #and other communications.

  exec { "Stop iptables on slave node":
    command     => "systemctl stop iptables" ,
    path        => [ '/bin' , '/sbin' , '/usr/bin' , '/usr/sbin' , ] ,
    logoutput   => true ,
    require => Class['docker'],
  }

  #Iptables has to be disabled on slave node.

  exec { "Disable iptables on slave node":
  command     => "systemctl disable iptables" ,
  path        => [ '/bin' , '/sbin' , '/usr/bin' , '/usr/sbin' , ] ,
  logoutput   => true ,
  require => Exec["Stop iptables on slave node"],
  }

  #After iptables is stopped and disabled on slave nodewe need to reload the daemon otherwise we get the
  #error says unable to find endpoints for the container, this is because docker module integrated along with
  #this mesos module enables firewall rules.
  exec { "Docker Daemon-Reload":
    command     => "systemctl daemon-reload" ,
    path        => [ '/bin' , '/sbin' , '/usr/bin' , '/usr/sbin' , ] ,
    logoutput   => true ,
    require => Exec["Disable iptables on slave node"],
  }

  #Docker service needs to be restarted after the iptables is stopped and disabled.
  exec { "Docker Service Restart":
    command     => "systemctl restart docker.service" ,
    path        => [ '/bin' , '/sbin' , '/usr/bin' , '/usr/sbin' , ] ,
    logoutput   => true ,
    require => Exec["Docker Daemon-Reload"],
  }
}