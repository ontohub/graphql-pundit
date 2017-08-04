require 'pundit'

module GraphQL
  module Pundit
    class Instrumenter
      attr_reader :current_user

      def initialize(current_user = :current_user)
        @current_user = current_user
      end

      def instrument(_type, field)
        if field.metadata[:authorize]
          old_resolve = field.resolve_proc
          resolve_proc = resolve_proc(current_user,
                                      old_resolve,
                                      field.metadata[:authorize])
          field.redefine do
            resolve resolve_proc
          end
        else
          field
        end
      end

      def resolve_proc(current_user, old_resolve, options)
        lambda do |obj, args, ctx|
          query = options[:query].to_s + '?'
          record = options[:record] || obj
          begin
            unless ::Pundit.authorize(ctx[current_user], record, query)
              raise ::Pundit::NotAuthorized 
            end
            old_resolve.call(obj, args, ctx)
          rescue ::Pundit::NotAuthorizedError
            if options[:raise]
              raise GraphQL::ExecutionError,
                    "You're not authorized to do this"
            end
          end
        end
      end
    end
  end
end
