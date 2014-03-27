
# default values come from install_server.sh
define redis::instance(
  $servername = $name, 
  $conf = {}, 
  $sentinel = false,
  $default_template = true,
) {

  # It's more programmatically, but I don't want a fuck*** template
  # and it is already provided by redis
  # More chance to have auto-compatibility with future version
  # and it's just fun sometimes

  # check parameters
  validate_string($servername)
  validate_hash($conf)
  validate_bool($sentinel)
  validate_bool($default_template)

  # default value if not set
  if (empty($conf) or $conf[port] == '') {
    $port = 6379
  } else {
    $port = $conf[port]
  }

  if (empty($conf) or $conf[pidfile] == '') {
    $pidfile = "/var/run/redis_${port}.pid"
  } else {
    $pidfile = $conf[pidfile]
  }

  if (empty($conf) or $conf[logfile] == '') {
    $logfile = "/var/log/redis_${port}.log"
  } else {
    $logfile = $conf[logfile]
  }

  if (empty($conf) or $conf[dir] == '') {
    $dir = "/var/lib/redis/${port}"
  } else {
    $dir = $conf[dir]
  }

  $conf_tmp = merge($conf, {port => $port, pidfile => $pidfile, logfile => $logfile, dir => $dir})

  if($default_template) {

    # select the good template
    if ($sentinel) {
      $default_conf_file = 'sentinel.conf'
    } else {
      $default_conf_file = 'redis.conf'
    }

    # copy redis.conf or sentinel.conf
    exec { "copy default conf file ${servername}":
      cwd     => "${redis::tmp}/redis-${redis::version}",
      command => "cp ${default_conf_file} ${redis::conf_dir}/${port}.conf",
      path    => '/bin:/usr/bin',
      creates => "${redis::conf_dir}/${port}.conf",
      require => [Exec['install redis'], File['conf dir']],
      notify  => File["conf file ${servername}"],
    }
  }

  # create an empty file if $default_template == false
  file { "conf file ${servername}":
    ensure  => file,
    path    => "${redis::conf_dir}/${port}.conf",
    owner   => root,
    group   => root,
    mode    => 644,
    require => [Exec['install redis'], File['conf dir']],
  }

  file { "data dir ${servername}":
    ensure => directory,
    name   => $dir,
  }

  file { "init file ${servername}":
    ensure  => file,
    name    => "/etc/init.d/redis_${port}",
    owner   => root,
    group   => root,
    mode    => 755,
    content => template("${module_name}/redis_port.erb"),
    notify  => Service["redis ${servername}"],
  }

  # override properties
  $conf_tmp.each |$key, $value| {

    # TODO, clean this mess
    # maybe replace by slice function but need puppet 3.5
    $key_arr = split($key, '#')
    $size = size($key_arr)
    if($size == 2) {
      $final_key = $key_arr[1]
    } else {
      $final_key = $key_arr[0]
    }

    # magic regex
    $regex = "^(#\\s)?(${final_key}\\s)\
(((?!and)(?!192.168.1.100\\s10.0.0.1)\
(?!is\\sset)\
[A-Za-z0-9\\._\\-\"/\\s]+)\
|(<master-password>)|(<masterip>\\s<masterport>)\
|(<bytes>))$"

    file_line { "conf_${servername}_${final_key}":
      path    => "${redis::conf_dir}/${port}.conf",
      line    => $size ? { 2 => "# ${final_key} ${value}", default => "${final_key} ${value}" },
      match   => $regex,
      require => File["conf file ${servername}"],
      notify  => Service["redis ${servername}"],
    }
  }

  service { "redis ${servername}":
    name       => "redis_${port}",
    enable     => true,
    ensure     => running,
    hasrestart => true,
    hasstatus  => false,
    status     => "/bin/service redis_${port} status | grep --quiet \"Redis is running\"",
    require    => [Exec['install redis'], File["data dir ${servername}"]],
  }
}