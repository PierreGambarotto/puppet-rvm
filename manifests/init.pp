class rvm {

  Exec{
    path => "/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin"
  }

  if ! defined(Package[curl]){
    package{curl:}
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

  define package_if_not_defined($ensure='present'){
    if ! defined(Package[$name]) {
      package{$name:
        ensure => $ensure
      }
    }
  }

  define class_if_not_defined(){
    if ! defined(Class[$name]) {
      include $name
    }
  }

  define ruby($version = ''){
    Exec{
      path => "/usr/local/bin:/usr/bin:/usr/sbin:/bin:/sbin:/usr/local/rvm/bin"
    }
    $install_version = $version ? { '' => $name, default => $version }
    case $install_version {
      /(1\.8\.7|1\.9\.3|ree|rbx)/: { 
        $mri_packages = [ 'build-essential','openssl','libreadline6','libreadline6-dev','curl','git-core','zlib1g','zlib1g-dev','libssl-dev','libyaml-dev','libsqlite3-dev','sqlite3','libxml2-dev','libxslt-dev','autoconf','libc6-dev','ncurses-dev','automake','libtool','bison','subversion']
        $required = Package_if_not_defined[$mri_packages]
        package_if_not_defined{$mri_packages:}
      }
      'jruby': {
        class_if_not_defined{java:}
        $required = Class_if_not_defined[java]
      }
    }
      
    exec{"install ruby: $install_version":
      require => [$required, Exec["rvm install"]],
      command => "rvm install $install_version",
      timeout => "0",
      logoutput => true,
      unless => "ls -l /usr/local/rvm/rubies/*$install_version*"
    }

    file{"/usr/local/rvm/environments/default":
      require => Exec["make $install_version the default rvm ruby"],
      group => "rvm",
      ensure => present
    }

    exec{"make $install_version the default rvm ruby":
# rvm alias create default <version>
# see http://www.engineyard.com/blog/2012/rvm-stable-and-more/
      command => "bash -c 'source /etc/profile.d/rvm.sh; rvm --default $install_version'",
      logoutput => true,
      require => Exec["install ruby: $install_version"],
      unless => "grep $install_version /usr/local/rvm/environments/default",
    }

    file{"/usr/local/rvm/environments/default_apache":
      require => Exec["generate rvm conf for apache2"],
      ensure => present
    }
    exec{"generate rvm conf for apache2":
      command => "sed -e 's/\; */\\n/g' /usr/local/rvm/environments/default | grep -E '(GEM_HOME|GEM_PATH|MY_RUBY_HOME|RUBY_VERSION)=' | sed -e 's/^\([^=]*\)=\(.*\)$/SetEnV \1 \2/' | tee /usr/local/rvm/environments/default_apache",
      require => [Exec["make $install_version the default rvm ruby"],File["/usr/local/rvm/environments/default"]],
      logoutput => true,
      unless => "grep RUBY_VERSION /usr/local/rvm/environments/default_apache",
    }
    
  }

#  Package{
#    require => File["/usr/local/rvm/environments/default"]
#  }

}
