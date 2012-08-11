# -*- encoding: utf-8 -*-
require File.expand_path('../lib/muon/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["DRUG"]
  # gem.email         = [""]
  gem.description   = %q{Distributed time tracking tool}
  gem.summary       = %q{Distributed time tracking tool}
  gem.homepage      = "http://drug.org.pl"

  gem.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  gem.name          = "muon"
  gem.require_paths = ["lib"]
  gem.version       = Muon::VERSION

  gem.add_dependency('gli')

  gem.add_development_dependency('rake')
  gem.add_development_dependency('delorean')
end
