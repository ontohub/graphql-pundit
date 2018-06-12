# frozen_string_literal: true

require 'graphql'
require 'graphql-pundit/authorization'
require 'graphql-pundit/scope'

module GraphQL
  module Pundit
    # Field class that contains authorization and scope behavior
    class Field < GraphQL::Schema::Field
      prepend GraphQL::Pundit::Scope
      prepend GraphQL::Pundit::Authorization
    end
  end
end
