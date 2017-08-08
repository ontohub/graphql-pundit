# frozen_string_literal: true

unless defined?(SimpleCov)
  require 'simplecov'
  SimpleCov.start
  require 'codecov'
  formatters = [SimpleCov::Formatter::HTMLFormatter]
  formatters << SimpleCov::Formatter::Codecov if ENV['CI']
  SimpleCov.formatters = formatters
end
