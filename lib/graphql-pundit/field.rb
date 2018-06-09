require 'graphql'
require 'graphql-pundit/authorization'
require 'graphql-pundit/scope'

module GraphQL::Pundit
  class Field < GraphQL::Schema::Field
    prepend GraphQL::Pundit::Scope
    prepend GraphQL::Pundit::Authorization
  end
end
