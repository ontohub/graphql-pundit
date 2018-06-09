require 'graphql'
require 'graphql-pundit/authorization'

module GraphQL::Pundit
  class Field < GraphQL::Schema::Field
    prepend Authorization
  end
end
