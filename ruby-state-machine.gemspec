# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'ruby-state-machine/version'

Gem::Specification.new do |gem|
  gem.name              = "ruby-state-machine"
  gem.version           = RubyStateMachine::VERSION::STRING
  gem.authors           = ["tangledpath"]
  gem.email             = ["steven.miers@gmail.com"]
  gem.description       = %q{A ruby state machine}
  gem.summary           = %q{A full-featured state machine gem for use within ruby. }
  gem.homepage          = "http://github.com/tangledpath/ruby-state-machine"
  gem.rubyforge_project = 'ruby-state-machine'
  gem.has_rdoc          = true
  gem.extra_rdoc_files  = ['README.md']
  gem.files             =  Dir.glob('lib/**/*.rb') 
  gem.executables       = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files        = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths     = ["lib", "ext"]
end
