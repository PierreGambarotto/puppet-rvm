Facter.add("default_rvm_ruby_string") do
  setcode do
    (%x{grep rvm_ruby_string= /usr/local/rvm/environments/default}||"").chomp.split('=')[1][1..-2]
  end
end
Facter.add("default_rvm_gem_home") do
  setcode do
    (%x{grep GEM_HOME= /usr/local/rvm/environments/default}||"").chomp.split('=')[1][1..-2]
  end
end
