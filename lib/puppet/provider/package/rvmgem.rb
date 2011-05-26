require 'puppet/provider/package'

Puppet::Type.type(:package).provide :rvmgem, :parent => :gem do

  commands :gemcmd => "/usr/local/rvm/bin/gem"

  has_feature :versionable


end
