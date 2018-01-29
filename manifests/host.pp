
define tinc::host(
  $netname,
  $subnets,
  $publickey,
  $publicaddress=undef,
  $nodename=$name,
)
{

  file { "/etc/tinc/${netname}/hosts/${nodename}":
    ensure  => present,
    owner   => 'root',
    group   => 'root',
    mode    => '0644',
    content => epp('tinc/host.epp', {
      'publicaddress'   => $publicaddress,
      'subnets'         => $subnets,
      'publickey'       => $publickey,
    }),
  }

}
