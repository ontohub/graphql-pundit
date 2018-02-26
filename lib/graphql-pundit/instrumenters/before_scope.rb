# frozen_string_literal: true

require 'pundit'

module GraphQL
  module Pundit
    module Instrumenters
      # Instrumenter that supplies `scope`
      class BeforeScope
        # Applies the scoping to the passed object
        class ScopeResolver
          attr_reader :current_user, :scope, :old_resolver

          def initialize(current_user, scope, old_resolver, field)
            @current_user = current_user
            @old_resolver = old_resolver
            @field = field

            unless valid_value?(scope)
              raise ArgumentError, 'Invalid value passed to `scope`'
            end

            @scope = scope
          end

          def call(root, arguments, context)
            warn 'Using `scope` is deprecated and might be removed in the future. Please use `before_scope` or `after_scope` instead.' if @field.metadata[:before_scope][:deprecated]
            scope_proc = new_scope(scope)
            resolver_result = scope_proc.call(root, arguments, context)
            old_resolver.call(resolver_result, arguments, context)
          end

          private

          def new_scope(scope)
            return scope if proc?(scope)

            lambda do |root, _arguments, context|
              scope = find_scope(root, scope)
              scope.new(context[current_user], root).resolve
            end
          end

          def find_scope(root, scope)
            if !inferred?(scope)
              scope::Scope
            else
              # Special case for Sequel datasets that do not respond to
              # ActiveModel's model_name
              infer_from = if root.respond_to?(:model)
                             root.model
                           else
                             root
                           end
              ::Pundit::PolicyFinder.new(infer_from).scope!
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
          scope_metadata = field.metadata[:before_scope]
          return field unless scope_metadata
          scope = scope_metadata[:proc]

          old_resolver = field.resolve_proc
          resolver = ScopeResolver.new(current_user, scope, old_resolver, field)

          field.redefine do
            resolve resolver
          end
        end
      end
    end
  end
end
