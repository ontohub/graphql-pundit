# frozen_string_literal: true

require 'graphql-pundit/instrumenter'
require 'graphql-pundit/version'

require 'graphql'

# Define `authorize` and `authorize!` helpers
module GraphQL
  # rubocop:disable Metrics/MethodLength
  def self.assign_authorize(raise_unauthorized)
    # rubocop:enable Metrics/MethodLength
    lambda do |defn, query = nil, policy: nil, record: nil|
      opts = {record: record,
              query: query || defn.name,
              policy: policy,
              raise: raise_unauthorized}
      if query.respond_to?(:call)
        opts = {proc: query, raise: raise_unauthorized}
      end
      Define::InstanceDefinable::AssignMetadataKey.new(:authorize).
        call(defn, opts)
    end
  end

  def self.assign_scope
    lambda do |defn, proc = :infer_scope|
      Define::InstanceDefinable::AssignMetadataKey.new(:scope).
        call(defn, proc)
    end
  end

  Field.accepts_definitions(authorize: assign_authorize(false),
                            authorize!: assign_authorize(true),
                            scope: assign_scope)
end
