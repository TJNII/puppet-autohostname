class autohostname (
  $hostname_prefix,
  $hostname_suffix,
  $vgs_search_string,
  ) {
    
  package { "uuid-runtime":
    ensure => installed,
  }
  
  file { '/usr/sbin/autohostname.sh':
    ensure  => file,
    mode    => 755,
    source  => 'puppet:///modules/autohostname/usr/sbin/autohostname.sh',
    require => Package["uuid-runtime"],
  }
  
  file { '/etc/init.d/autohostname':
    ensure  => file,
    mode    => 755,
    content => template("autohostname/etc/init.d/autohostname.erb"),
  }
  
  service { 'autohostname':
    ensure  => running,
    enable  => true,
    require => [ File["/usr/sbin/autohostname.sh"],
                 File["/etc/init.d/autohostname"] ]
  }      
}
