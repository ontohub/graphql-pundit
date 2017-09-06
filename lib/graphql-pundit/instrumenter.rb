# frozen_string_literal: true

require 'pundit'
require 'graphql-pundit/instrumenters/authorization'
require 'graphql-pundit/instrumenters/scope'

module GraphQL
  module Pundit
    # Intrumenter combining the authorization and scope instrumenters
    class Instrumenter
      attr_reader :current_user,
                  :authorization_instrumenter,
                  :scope_instrumenter

      def initialize(current_user = :current_user)
        @current_user = current_user
        @authorization_instrumenter = Instrumenters::Authorization.
          new(current_user)
        @scope_instrumenter = Instrumenters::Scope.new(current_user)
      end

      def instrument(type, field)
        scoped_field = scope_instrumenter.instrument(type, field)
        authorization_instrumenter.instrument(type, scoped_field)
      end
    end
  end
end
