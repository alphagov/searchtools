$:.unshift(".") unless $:.include?(File.expand_path("."))

require 'bundler'
Bundler.require :default, :test

require 'rspec/core'
require 'rspec/expectations'
require 'rspec/matchers'


RSpec.configure do |config|
  config.mock_with :mocha
end
