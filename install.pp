# Class: mesos::install
#
# This class manages Mesos package installation.
#
# Parameters:
# [*ensure*] - 'present' for installing any version of Mesos
#   'latest' or e.g. '0.15' for specific version
#
# Sample Usage: is not meant for standalone usage, class is
# required by 'mesos::master' and 'mesos::slave'
#
class mesos::install(
  $ensure                  = 'present',
  $repo_source             = undef,
  $manage_python           = false,
  $python_package          = 'python',
  $remove_package_services = false,
) {
  # 'ensure_packages' requires puppetlabs/stdlib
  #
  # linux containers are now implemented natively
  # with usage of cgroups, requires kernel >= 2.6.24
  #
  # Python is required for web GUI (mesos could be build without GUI)
  include mesos::params

  if $manage_python {
    ensure_resource('package', [$python_package],
      {'ensure' => 'present', 'require' => Package['mesos']}
    )
  }

  class {'mesos::repo':
    source => $repo_source,
  }

  # a debian (or other binary package) must be available,
  # see https://github.com/deric/mesos-deb-packaging
  # for Debian packaging
  package { 'mesos':
    ensure  => $ensure,
    require => [ Class['mesos::repo'], Class['oracle_java'], ]
  }

  if ($remove_package_services and $::osfamily == 'redhat' and $::operatingsystemmajrelease == '6') {
    file { [
      '/etc/init/mesos-master.conf', '/etc/init/mesos-slave.conf'
    ]:
      ensure  => absent,
      require => Package['mesos'],
    }
  }
}
