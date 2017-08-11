# frozen_string_literal: true
require 'graphql-pundit/instrumenter'
require 'graphql-pundit/version'

require 'graphql'

module GraphQL
  def self.assign_authorize(raise_unauthorized)
    lambda do |defn, query, record = nil|
      if query.respond_to?(:call)
        GraphQL::Define::InstanceDefinable::AssignMetadataKey.new(:authorize).
          call(defn, proc: query, raise: raise_unauthorized)
      else
        GraphQL::Define::InstanceDefinable::AssignMetadataKey.new(:authorize).
          call(defn, record: record, query: query, raise: raise_unauthorized)
      end
    end
  end
  GraphQL::Field.accepts_definitions authorize: assign_authorize(false)
  GraphQL::Field.accepts_definitions authorize!: assign_authorize(true)
end
