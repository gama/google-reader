# -*- encoding: utf-8 -*-
require File.expand_path('../lib/google-reader/version', __FILE__)

Gem::Specification.new do |s|
    s.add_runtime_dependency('rack', '~> 1.2')
    s.add_runtime_dependency('json', '~> 1.4')
    s.add_runtime_dependency('hashie', '~> 0.4.0')
    s.add_runtime_dependency('oauth', '~> 0.4.0')
    s.authors = ['Gustavo Machado C. Gama']
    s.description = %q{A Ruby wrapper for the 'Google Reader' unofficial API}
    s.email = ['gustavo.gama@gmail.com']
    s.executables = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
    s.files = `git ls-files`.split("\n")
    s.homepage = 'http://github.com/gama/google-reader'
    s.name = 'google-reader'
    s.platform = Gem::Platform::RUBY
    s.require_paths = ['lib']
    s.required_rubygems_version = Gem::Requirement.new(">= 1.3.6") if s.respond_to? :required_rubygems_version=
    s.summary = %q{Ruby wrapper for the 'Google Reader' API}
    s.test_files = `git ls-files -- test/*`.split("\n")
    s.version = Google::Reader::VERSION
end
