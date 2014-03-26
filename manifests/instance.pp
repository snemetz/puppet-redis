
define redis::instance(
  $servername = $name, 
  $conf = {}, 
  $sentinel = false,
) {

  # It's more programmatically, but I don't want a fuck*** template
  # and it is already provided by redis
  # More chance to have auto-compatibility with future version
  # and it's just fun sometimes

  validate_hash($conf)

  # default value if not set
  $port = (empty($conf)
          or $conf[port] == '') ? {
                                    false => $conf[port],
                                    default => 6379,
                                  }

  $pidfile = (empty($conf)
              or $conf[pidfile] == '') ? {
                                           false => $conf[pidfile],
                                           default => "/var/run/redis_${port}.pid",
                                         }

  $logfile = (empty($conf)
              or $conf[logfile] == '') ? {
                                           false => $conf[logfile],
                                           default => "/var/log/redis_${port}.log",
                                         }

  $dir = (empty($conf)
          or $conf[dir] == '') ? {
                                   false => $conf[dir],
                                   default => "/var/lib/redis/${port}",
                                 }

  $conf_tmp = merge($conf, {port => $port, pidfile => $pidfile, logfile => $logfile, dir => $dir})

  # Select the good template
  if ($sentinel) {
    $default_conf_file = 'sentinel.conf'
  } else {
    $default_conf_file = 'redis.conf'
  }

  # copy redis.conf or sentinel.conf
  exec { "copy default conf file ${servername}":
    cwd     => "${tmp}/redis-${version}",
    command => "cp ${default_conf_file} ${conf_dir}/${port}.conf",
    path    => '/bin:/usr/bin',
    creates => "${conf_dir}/${port}.conf",
    require => [Exec['install redis'], File['conf dir']],
  }

  file { "data dir ${servername}":
    ensure => directory,
    name   => $dir,
  }

  file { "init file ${servername}":
    ensure  => 'file',
    name    => "/etc/init.d/redis_${port}",
    owner   => root,
    group   => root,
    mode    => 755,
    content => template("${module_name}/redis_port.erb"),
    notify  => Service["redis ${servername}"],
  }

  # override properties
  $conf_tmp.each |$key, $value| {
    file_line { "conf_${servername}_${key}":
      path    => "${conf_dir}/${port}.conf",
      line    => "${key} ${value}",
      match   => "^(#\s)?(${key}\s)((?!and)[A-Za-z0-9\\._\\-\"/\s]+)$",
      require => Exec["copy default conf file ${servername}"],
      notify  => Service["redis ${servername}"],
    }
  }

  service { "redis ${servername}":
    name => "redis_${port}",
    enable => true,
    ensure => running,
    hasrestart => true,
    hasstatus => false,
    status => "/bin/service redis_${port} status | grep --quiet \"Redis is running\"",
    require => [Exec['install redis'], File["data dir ${servername}"]],
  }
}