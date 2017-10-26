# frozen_string_literal: true

require 'pundit'

module GraphQL
  module Pundit
    module Instrumenters
      # Instrumenter that supplies `authorize`
      class Authorization
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

        # rubocop:disable Metrics/MethodLength, Metrics/AbcSize
        # rubocop:disable Metrics/CyclomaticComplexity
        # rubocop:disable Metrics/PerceivedComplexity
        # rubocop:disable Metrics/BlockLength
        def resolve_proc(current_user, old_resolve, options)
          lambda do |obj, args, ctx|
            begin
              result = if options[:proc]
                         options[:proc].call(obj, args, ctx)
                       else
                         query = options[:query].to_s + '?'
                         record = if options[:record].respond_to?(:call)
                                    options[:record].call(obj, args, ctx)
                                  else
                                    options[:record] || obj
                                  end
                         policy = options[:policy] || record
                         policy = ::Pundit::PolicyFinder.new(policy).policy!
                         policy = policy.new(ctx[current_user], record)
                         policy.public_send(query)
                       end
              unless result
                raise ::Pundit::NotAuthorizedError, query: query,
                                                    record: record,
                                                    policy: policy
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
end
