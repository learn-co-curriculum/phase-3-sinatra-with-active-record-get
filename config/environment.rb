ENV['RACK_ENV'] ||= 'development'
require 'logger'

# Require in Gems
require 'bundler/setup'
Bundler.require(:default, ENV.fetch('RACK_ENV', nil))

# Require in all files in 'app' directory
require_all 'app'