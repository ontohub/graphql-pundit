# frozen_string_literal: true

require 'pundit'

module GraphQL
  module Pundit
    module Instrumenters
      # Instrumenter that supplies `scope`
      class Scope
        # Applies the scoping to the passed object
        class ScopeResolver
          attr_reader :current_user, :scope, :old_resolver

          def initialize(current_user, scope, old_resolver)
            @current_user = current_user
            @old_resolver = old_resolver

            unless valid_value?(scope)
              raise ArgumentError, 'Invalid value passed to `scope`'
            end

            @scope = new_scope(scope)
          end

          def call(root, arguments, context)
            new_scope = scope.call(root, arguments, context)
            old_resolver.call(new_scope, arguments, context)
          end

          private

          def new_scope(scope)
            return scope if proc?(scope)

            lambda do |root, _arguments, context|
              unless inferred?(scope)
                root.define_singleton_method(:policy_class) { scope }
              end

              ::Pundit.policy_scope!(context[current_user], root)
            end
          end

          def valid_value?(value)
            value.is_a?(Class) || inferred?(value) || proc?(value)
          end

          def proc?(value)
            value.respond_to?(:call)
          end

          def inferred?(value)
            value == :infer_scope
          end
        end

        attr_reader :current_user

        def initialize(current_user = :current_user)
          @current_user = current_user
        end

        def instrument(_type, field)
          scope = field.metadata[:scope]
          return field unless scope

          old_resolver = field.resolve_proc
          resolver = ScopeResolver.new(current_user, scope, old_resolver)

          field.redefine do
            resolve resolver
          end
        end
      end
    end
  end
end
