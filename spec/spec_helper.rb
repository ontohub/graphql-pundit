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

Field = GraphQL::Pundit::Field

class BaseObject < GraphQL::Schema::Object
  field_class GraphQL::Pundit::Field
end

class Query < BaseObject
  field :test, Int, null: true
end

class Schema < GraphQL::Schema
  query(Query)
end

def spec_context
  GraphQL::Query::Context.new(query: Query, schema: Schema, object: {}, values: {})
end

class CarDataset
  attr_reader :cars

  def initialize(cars)
    @cars = cars
  end

  def object
    self
  end

  def where(&block)
    self.class.new(cars.select(&block))
  end

  def first
    cars.first
  end

  def all
    self
  end

  def to_a
    @cars
  end

  def model
    Car
  end

  def names
    self.to_a.map(&:name)
  end
end

class Car
  attr_reader :name, :country

  def self.all
    CarDataset.new(CARS)
  end

  def self.object
    self
  end

  def self.where(&block)
    all.where(&block)
  end

  def self.first(&block)
    where(&block).first
  end

  def object
    self
  end

  def self.longer_then_five
    self.where { |c| c.name.length > 5 }
  end

  def initialize(name, country)
    @name = name
    @country = country
  end

  CARS = [{name: 'Toyota', country: 'Japan'},
          {name: 'Volkswagen Group', country: 'Germany'},
          {name: 'Hyundai', country: 'South Korea'},
          {name: 'General Motors', country: 'USA'},
          {name: 'Ford', country: 'USA'},
          {name: 'Nissan', country: 'Japan'},
          {name: 'Honda', country: 'Japan'},
          {name: 'Fiat Chrysler', country: 'Italy'},
          {name: 'Renault', country: 'France'},
          {name: 'Groupe PSA', country: 'France'},
          {name: 'Suzuki', country: 'Japan'},
          {name: 'SAIC', country: 'China'},
          {name: 'Daimler', country: 'Germany'},
          {name: 'BMW', country: 'Germany'},
          {name: 'Changan', country: 'China'},
          {name: 'Mazda', country: 'Japan'},
          {name: 'BAIC', country: 'China'},
          {name: 'Dongfeng Motor', country: 'China'},
          {name: 'Geely', country: 'China'},
          {name: 'Great Wall', country: 'China'}].
    map { |c| Car.new(c[:name], c[:country]) }
end

class CarPolicy
  class Scope
    attr_reader :scope
    def initialize(_user, scope)
      @scope = scope
    end

    def resolve
      @scope.where { |c| c.country == 'Germany' }
    end
  end

  def initialize(_user, car)
    @car = car
  end

  def name?
    false
  end

  def display_name?
    false
  end
end

class ChineseCarPolicy
  class Scope
    def initialize(_user, scope)
      @scope = scope
    end

    def resolve
      @scope.where { |c| c.country == 'China' }
    end
  end

  def initialize(_user, car)
    @car = car
  end

  def name?
    false
  end

  def display_name?
    false
  end
end
