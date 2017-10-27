# frozen_string_literal: true

require 'graphql-pundit/instrumenter'
require 'graphql-pundit/version'

require 'graphql'

# Defines authorization related helpers
module GraphQL
  # Defines `authorize` and `authorize!` helpers
  class AuthorizationHelper
    attr_reader :raise_unauthorized

    def initialize(raise_unauthorized)
      @raise_unauthorized = raise_unauthorized
    end

    def call(defn, query = nil, policy: nil, record: nil)
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

  # Defines `scope` helper
  class ScopeHelper
    def call(defn, proc = :infer_scope)
      Define::InstanceDefinable::AssignMetadataKey.new(:scope).
        call(defn, proc)
    end
  end

  Field.accepts_definitions(authorize: AuthorizationHelper.new(false),
                            authorize!: AuthorizationHelper.new(true),
                            scope: ScopeHelper.new)
end
