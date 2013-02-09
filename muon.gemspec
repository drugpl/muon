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

  gem.add_dependency('gli',               "= 2.5.4")
  gem.add_dependency('chronic_duration',  "= 0.9.6")
  gem.add_dependency('multi_json',        "= 1.5.0")
  gem.add_dependency('veritas',           "= 0.0.7")
  gem.add_dependency('activesupport',     "= 3.2.11")
  gem.add_dependency('hirb')

  gem.add_development_dependency('rake')
  gem.add_development_dependency('delorean')
  gem.add_development_dependency('turn')
end
