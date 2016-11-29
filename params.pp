class mesos::params {

  $config_file_owner                  = 'root'

  $config_file_group                  = 'root'

  $config_file_mode                   = '0644'

  $def_master                         = 'UNDEFINED!'

  $def_master_fqdn                    = 'UNDEFINED!'

  $def_containerizers                 = 'docker,mesos'

  $def_executor_registration_timeout  = '5mins'

  $def_gc_delay                       = '1days'

  $def_gc_disk_headroom               = 0.18

  $def_launcher_dir                   = '/usr/libexec/mesos'

  $def_resource                       = 'cpus:2;ports:[7000-9050, 31000-59000]'

  $def_attribute                      = 'UNDEFINED!'

  $def_artifactory_url                    = 'UNDEFINED!'

  $def_artifactory_username               = 'UNDEFINED!'

  $def_artifactory_password               = 'UNDEFINED!'

  $def_artifactory_email                  = 'UNDEFINED!'

  $def_node_number                    = 'UNDEFINED!'

  $def_zk_id                          = 1

  $def_quorum                         = 1

  $def_zookeeper                      = 'UNDEFINED!'

  $def_fw_interface                   = 'ens32'

  $def_zoo_cfg                        = ["server.1=${::fqdn}:2888:3888",]

  $zoo_conf                           = 'zoo.conf.erb'

  $def_zk                             = []

  $zk_conf                           = 'zk.conf.erb'

}