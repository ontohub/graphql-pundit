# frozen_string_literal: true

require 'pundit'
require_relative 'scope'

module GraphQL
  module Pundit
    module Instrumenters
      # Instrumenter that supplies `scope`
      class AfterScope < Scope

        SCOPE_KEY = :after_scope

        # Applies the scoping to the passed object
        class ScopeResolver < ScopeResolver
          def call(root, arguments, context)
            resolver_result = old_resolver.call(root, arguments, context)
            scope_proc = new_scope(scope)
            scope_proc.call(resolver_result, arguments, context)
          end
        end
      end
    end
  end
end
