# frozen_string_literal: true

require 'pundit'

module GraphQL
  module Pundit
    module Instrumenters
      # Instrumenter that supplies `authorize`
      class Authorization
        # This does the actual Pundit authorization
        class AuthorizationResolver
          attr_reader :current_user, :old_resolver, :options
          def initialize(current_user, old_resolver, options)
            @current_user = current_user
            @old_resolver = old_resolver
            @options = options
          end

          def call(root, arguments, context)
            unless authorize(root, arguments, context)
              raise ::Pundit::NotAuthorizedError
            end
            old_resolver.call(root, arguments, context)
          rescue ::Pundit::NotAuthorizedError
            if options[:raise]
              raise GraphQL::ExecutionError, "You're not authorized to do this"
            end
          end

          private

          def authorize(root, arguments, context)
            if options[:proc]
              options[:proc].call(root, arguments, context)
            else
              record = record(root, arguments, context)
              ::Pundit::PolicyFinder.new(policy(record)).policy!.
                new(context[current_user], record).public_send(query)
            end
          end

          def query
            @query ||= options[:query].to_s + '?'
          end

          def policy(record)
            options[:policy] || record
          end

          def record(root, arguments, context)
            if options[:record].respond_to?(:call)
              options[:record].call(root, arguments, context)
            else
              options[:record] || root
            end
          end
        end

        attr_reader :current_user

        def initialize(current_user = :current_user)
          @current_user = current_user
        end

        def instrument(_type, field)
          return field unless field.metadata[:authorize]
          old_resolver = field.resolve_proc
          resolver = AuthorizationResolver.new(current_user,
                                               old_resolver,
                                               field.metadata[:authorize])
          field.redefine do
            resolve resolver
          end
        end
      end
    end
  end
end
