# frozen_string_literal: true

require 'pundit'
require 'graphql-pundit/instrumenters/authorization'
require 'graphql-pundit/instrumenters/before_scope'
require 'graphql-pundit/instrumenters/after_scope'

module GraphQL
  module Pundit
    # Intrumenter combining the authorization and scope instrumenters
    class Instrumenter
      attr_reader :current_user,
                  :authorization_instrumenter,
                  :before_scope_instrumenter,
                  :after_scope_instrumenter

      def initialize(current_user = :current_user)
        @current_user = current_user
        @authorization_instrumenter =
          Instrumenters::Authorization.new(current_user)
        @before_scope_instrumenter =
          Instrumenters::BeforeScope.new(current_user)
        @after_scope_instrumenter = Instrumenters::AfterScope.new(current_user)
      end

      def instrument(type, field)
        before_scoped_field = before_scope_instrumenter.instrument(type, field)
        after_scoped_field = after_scope_instrumenter.
          instrument(type, before_scoped_field)
        authorization_instrumenter.instrument(type, after_scoped_field)
      end
    end
  end
end
