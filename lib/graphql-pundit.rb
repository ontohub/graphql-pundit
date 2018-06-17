# frozen_string_literal: true

require 'graphql-pundit/instrumenter'
require 'graphql-pundit/field'
require 'graphql-pundit/authorization'
require 'graphql-pundit/scope'
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

    def call(defn, *args, policy: nil, record: nil)
      query = args[0] || defn.name
      opts = {record: record,
              query: query,
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
    def initialize(before_or_after, deprecated: false)
      @before_or_after = before_or_after
      @deprecated = deprecated
    end

    def call(defn, proc = :infer_scope)
      opts = {proc: proc, deprecated: @deprecated}
      Define::InstanceDefinable::AssignMetadataKey.
        new(:"#{@before_or_after}_scope").
        call(defn, opts)
    end
  end

  Field.accepts_definitions(authorize: AuthorizationHelper.new(false),
                            authorize!: AuthorizationHelper.new(true),
                            after_scope: ScopeHelper.new(:after),
                            before_scope: ScopeHelper.new(:before),
                            scope: ScopeHelper.new(:before, deprecated: true))
end
