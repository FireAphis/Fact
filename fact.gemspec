# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)
require "fact/version"

Gem::Specification.new do |s|
  s.name        = "fact"
  s.version     = Fact::VERSION
  s.authors     = ["FireAphis"]
  s.email       = ["FireAphis@gmail.com"]
  s.homepage    = "https://github.com/FireAphis/Fact"
  s.summary     = %q{Interactive ClearCase CLI and ClearCase wrapper API.}
  s.description = %q{A small project intended to make a life with ClearCase a little bit happier. It supplies an intuitive and interactive ClearCase CLI and ClearCase wrapper API.}

  s.has_rdoc = true
  s.extra_rdoc_files = ['bin/fact']
  s.rdoc_options << '--main' << 'bin/fact' << '--include' << 'bin'

  s.requirements << 'ClearCase ClearTool'
  s.add_dependency('highline', '>= 1.6.0')

  s.rubyforge_project = "fact"

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]
end
