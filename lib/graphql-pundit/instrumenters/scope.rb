# frozen_string_literal: true

require 'pundit'

module GraphQL
  module Pundit
    module Instrumenters
      class Scope
        attr_reader :current_user

        def initialize(current_user = :current_user)
          @current_user = current_user
        end

        def instrument(_type, field)
          scope = field.metadata[:scope]
          return field unless scope
          unless valid_value?(scope)
            raise ArgumentError, 'Invalid value passed to `scope`'
          end

          old_resolve = field.resolve_proc

          scope_proc = lambda do |obj, _args, ctx|
            ::Pundit.policy_scope!(ctx[current_user], obj)
          end
          scope_proc = scope if proc?(scope)

          field.redefine do
            resolve(lambda do |obj, args, ctx|
              new_scope = scope_proc.call(obj, args, ctx)
              old_resolve.call(new_scope, args, ctx)
            end)
          end
        end

        private

        def valid_value?(value)
          inferred?(value) || proc?(value)
        end

        def proc?(value)
          value.respond_to?(:call)
        end

        def inferred?(value)
          value == :infer_scope
        end
      end
    end
  end
end
