# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name          = "searchtools"
  s.version       = "0.8.3"
  s.platform      = Gem::Platform::RUBY
  s.authors       = ["Ben Griffiths"]
  s.email         = ["ben@alphagov.co.uk"]
  s.homepage      = "http://github.com/alphagov/searchtools"
  s.summary       = %q{Library extracting search tools from alpha}
  s.description   = %q{Library extracting search tools from alpha}

  s.files         = Dir[
    'lib/**/*',
    'README.md',
    'Gemfile',
    'Rakefile'
  ]
  s.test_files    = Dir['test/**/*']
  s.require_paths = ["lib"]

  s.add_dependency 'json', '~> 1.4.6'
  s.add_dependency 'nokogiri',"~> 1.4.0"
  s.add_dependency 'htmlentities', '~> 4.2.0'
  s.add_dependency 'rack'

  s.add_development_dependency 'rake', '~> 0.8.0'
  s.add_development_dependency 'rspec', '~> 2.5.0'
  s.add_development_dependency 'mocha', '~> 0.9.0'

end
