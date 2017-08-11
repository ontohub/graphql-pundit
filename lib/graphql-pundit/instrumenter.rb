# frozen_string_literal: true

require 'pundit'

module GraphQL
  module Pundit
    # The authorization Instrumenter
    class Instrumenter
      attr_reader :current_user

      def initialize(current_user = :current_user)
        @current_user = current_user
      end

      def instrument(_type, field)
        return field unless field.metadata[:authorize]

        old_resolve = field.resolve_proc
        resolve_proc = resolve_proc(current_user,
                                    old_resolve,
                                    field.metadata[:authorize])
        field.redefine do
          resolve resolve_proc
        end
      end

      private

      def resolve_proc(current_user, old_resolve, options)
        lambda do |obj, args, ctx|
          begin
            result = authorize(current_user, obj, args, ctx, options)
            raise ::Pundit::NotAuthorizedError unless result
            old_resolve.call(obj, args, ctx)
          rescue ::Pundit::NotAuthorizedError
            error_message = "You're not authorized to do this"
            raise GraphQL::ExecutionError, error_message if options[:raise]
          end
        end
      end

      def authorize(current_user, obj, args, ctx, options)
        if options[:proc]
          options[:proc].call(obj, args, ctx)
        else
          ::Pundit.authorize(ctx[current_user],
                             options[:record] || obj,
                             options[:query].to_s + '?')
        end
      end
    end
  end
end
