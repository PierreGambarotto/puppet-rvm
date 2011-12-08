class rvm {

  Exec{
    path => "/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin"
  }
  exec{"fetch rvm install script":
    command => "curl -s https://raw.github.com/wayneeseguin/rvm/master/binscripts/rvm-installer > /tmp/rvm_install",
    unless => "grep -l '/usr/bin/env bash' /tmp/rvm_install",
    require => Package[curl]
  }

  exec{"rvm install":
    command => "chmod +x /tmp/rvm_install && /tmp/rvm_install",
    creates => "/usr/local/rvm/bin/rvm",
    require => Exec["fetch rvm install script"]
  }

  group{rvm:
    require => Exec["rvm install"]
  }

  define ruby($version = ''){
    Exec{
      path => "/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin"
    }
    $install_version = $version ? { '' => $name, default => $version }
    case $install_version {
      /(1\.8\.7|1\.9\.2|ree)/: {
        if ! defined(Package['build-essential']) {package {'build-essential':}}
        if ! defined(Package['zlib1g-dev']) {package {'zlib1g-dev':}}
        if ! defined(Package['libssl-dev']) {package {'libssl-dev':}}
        if ! defined(Package['libreadline5-dev']) {package {'libreadline5-dev':}}
      }
      "jruby": {if ! defined(Class[java]) {include java}}
    }
    $required = $install_version ? {
      /(1\.8\.7|1\.9\.2|ree)/ => Package["build-essential", "zlib1g-dev", "libssl-dev", "libreadline5-dev"],
      "jruby" => Class[java]
    }
    exec{"install ruby: $install_version":
      path => "/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin",
      require => [$required, Exec["rvm install"]],
      command => "/usr/local/rvm/bin/rvm install $install_version",
      timeout => "-1",
      logoutput => true,
      unless => "ls -l /usr/local/rvm/rubies/*$install_version*"
    }

    file{"/usr/local/rvm/environments/default":
      require => Exec["make $install_version the default rvm ruby"],
      group => "rvm",
      ensure => present
    }

    exec{"make $install_version the default rvm ruby":
      command => "/usr/local/rvm/bin/rvm use --default $install_version",
      require => Exec["install ruby: $install_version"],
      unless => "grep $install_version /usr/local/rvm/environments/default",
      notify => Exec["generate rvm conf for apache2"]
    }

    exec{"generate rvm conf for apache2":
      require => File["/usr/local/rvm/environments/default"],
      command => "grep -E '(GEM_HOME|GEM_PATH|MY_RUBY_HOME|RUBY_VERSION)=' /usr/local/rvm/environments/default | sed -e 's/^\([^=]*\)=\(.*\)$/SetEnV \1 \2/' > /usr/local/rvm/environments/default_apache",
     refreshonly => true
    }
    
  }

  Package{
    require => File["/usr/local/rvm/environments/default"]
  }

}
