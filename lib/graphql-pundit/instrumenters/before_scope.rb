# frozen_string_literal: true

require 'pundit'
require_relative 'scope'

module GraphQL
  module Pundit
    module Instrumenters
      # Instrumenter that supplies `before_scope`
      class BeforeScope < Scope

        SCOPE_KEY = :before_scope

        # Applies the scoping to the passed object
        class ScopeResolver < ScopeResolver
          def call(root, arguments, context)
            if field.metadata[:before_scope][:deprecated]
              warn <<~DEPRECATION_WARNING
                Using `scope` is deprecated and might be removed in the future.
                Please use `before_scope` or `after_scope` instead.
              DEPRECATION_WARNING
            end
            scope_proc = new_scope(scope)
            resolver_result = scope_proc.call(root, arguments, context)
            old_resolver.call(resolver_result, arguments, context)
          end
        end
      end
    end
  end
end
