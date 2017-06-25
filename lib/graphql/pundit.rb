require_relative 'pundit/instrumenter'
require_relative 'pundit/version'

require 'graphql'

module GraphQL
  def self.assign_authorize(raise_unauthorized)
    lambda do |defn, query, record = nil|
      GraphQL::Define::InstanceDefinable::AssignMetadataKey.new(:authorize).call(
        defn,
        record: record, query: query, raise: raise_unauthorized
      )
    end
  end
  GraphQL::Field.accepts_definitions authorize: assign_authorize(false)
  GraphQL::Field.accepts_definitions authorize!: assign_authorize(true)
end
