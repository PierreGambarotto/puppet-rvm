Facter.add("default_rvm_ruby_string") do
  setcode do
    s = %x{grep rvm_ruby_string= /usr/local/rvm/environments/default}
    if s
      s =~ /rvm_ruby_string='([^']*)'/
      $1 
    else
      ""
    end
  end
end
Facter.add("default_rvm_gem_home") do
  setcode do
    s = %x{grep GEM_HOME= /usr/local/rvm/environments/default}
    if s
      s =~ /GEM_HOME='([^']*)'/
      $1 
    else
      ""
    end
  end
end
