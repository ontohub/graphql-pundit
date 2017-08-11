# frozen_string_literal: true

require 'graphql-pundit/instrumenter'
require 'graphql-pundit/version'

require 'graphql'

# Define `authorize` and `authorize!` helpers
module GraphQL
  def self.assign_authorize(raise_unauthorized)
    lambda do |defn, query = nil, record = nil|
      opts = {record: record,
              query: query || defn.name,
              raise: raise_unauthorized}
      if query.respond_to?(:call)
        opts = {proc: query, raise: raise_unauthorized}
      end
      Define::InstanceDefinable::AssignMetadataKey.new(:authorize).
        call(defn, opts)
    end
  end
  Field.accepts_definitions authorize: assign_authorize(false)
  Field.accepts_definitions authorize!: assign_authorize(true)
end
