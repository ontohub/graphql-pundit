# frozen_string_literal: true

require 'pundit'

module GraphQL
  module Pundit
    module Instrumenters
      # Instrumenter that supplies `scope`
      class Scope
        attr_reader :current_user

        def initialize(current_user = :current_user)
          @current_user = current_user
        end

        # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        def instrument(_type, field)
          # rubocop:enable Metrics/MethodLength, Metrics/AbcSize
          scope = field.metadata[:scope]
          return field unless scope
          unless valid_value?(scope)
            raise ArgumentError, 'Invalid value passed to `scope`'
          end

          old_resolve = field.resolve_proc

          scope_proc = lambda do |obj, _args, ctx|
            unless inferred?(scope)
              obj.define_singleton_method(:policy_class) { scope }
            end

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
          value.is_a?(Class) || inferred?(value) || proc?(value)
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
