define rvm::gem($ensure='present'){
  package{$name:
    ensure => $ensure,
    provider => rvmgem,
    require => File["/usr/local/rvm/environments/default"]
  }
}

