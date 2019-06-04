
define tinc::network(
  $vpnaddress,
  $vpnprefix='24',
  $vpnroute=[],
  $netname=$name,
  $autostart=true,
  $addressfamily='ipv4',
  $interface='vpn0',
  $connectto=[],
  $nodename=$::hostname,
  $keysize='4096'
)
{

  validate_array($vpnroute)
  validate_array($connectto)

  if ($autostart == true) {
    concat::fragment { "nets.boot-${netname}":
      content => "${netname}\n",
      target  => '/etc/tinc/nets.boot',
      order   => '02'
    }
  }

  file { "/etc/tinc/${netname}":
    ensure => directory
  }
  ->
  file { "/etc/tinc/${netname}/hosts/":
    ensure => directory,
    purge  => true
  }

  exec { "tinc-keygen-${netname}":
    command => "/usr/sbin/tincd -c /etc/tinc/${netname} -K ${keysize} -n ${netname}",
    creates => "/etc/tinc/${netname}/rsa_key.priv",
    require => File["/etc/tinc/${netname}/tinc.conf"]
  }
  ->
  exec { "tinc-pubkey-${netname}":
    command => "/usr/bin/openssl rsa -in /etc/tinc/${netname}/rsa_key.priv -out /etc/tinc/${netname}/rsa_key.pub -pubout",
    creates => "/etc/tinc/${netname}/rsa_key.pub",
  }

  file { "/etc/tinc/${netname}/tinc.conf":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('tinc/tinc.conf.epp', {
      'nodename'        => $nodename,
      'addressfamily'   => $addressfamily,
      'interface'       => $interface,
      'connectto'       => $connectto,
    }),
    notify  => Service['tinc'],
    require => File["/etc/tinc/${netname}"]
  }

  file { "/etc/tinc/${netname}/tinc-up":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0544',
    content => epp('tinc/tinc-up.epp', {
      'vpnaddress'      => $vpnaddress,
      'vpnprefix'       => $vpnprefix,
      'vpnroute'        => $vpnroute,
    }),
    require => File["/etc/tinc/${netname}"]
  }

  file { "/etc/tinc/${netname}/tinc-down":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0544',
    content => epp('tinc/tinc-down.epp', {}),
    require => File["/etc/tinc/${netname}"]
  }

  #Tinc::Host <<| netname == $netname |>>

}
