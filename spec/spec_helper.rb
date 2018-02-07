# frozen_string_literal: true

require_relative 'support/simplecov'

require 'bundler/setup'
require 'graphql-pundit'
require 'fuubar'
require 'pry'

RSpec.configure do |config|
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = '.rspec_status'

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.fuubar_progress_bar_options = {format: '[%B] %c/%C',
                                        progress_mark: '#',
                                        remainder_mark: '-'}
end
