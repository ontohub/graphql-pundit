# frozen_string_literal: true

require 'graphql-pundit/common'

module GraphQL
  module Pundit
    # Authorization methods to be included in the used Field class
    module Authorization
      def self.prepended(base)
        base.include(GraphQL::Pundit::Common)
      end

      # rubocop:disable Metrics/ParameterLists
      def initialize(*args, authorize: nil,
                            record: nil,
                            policy: nil,
                            **kwargs, &block)
        # rubocop:enable Metrics/ParameterLists
        # authorize! is not a valid variable name
        authorize_bang = kwargs.delete(:authorize!)
        @record = record if record
        @policy = policy if policy
        @authorize = authorize_bang || authorize
        @do_raise = !!authorize_bang
        super(*args, **kwargs, &block)
      end

      def authorize(*args, record: nil, policy: nil)
        @authorize = args[0] || true
        @record = record if record
        @policy = policy if policy
      end

      def authorize!(*args, record: nil, policy: nil)
        @do_raise = true
        authorize(*args, record: record, policy: policy)
      end

      def resolve_field(obj, args, ctx)
        resolve_helper(obj, args, ctx) { super(obj, args, ctx) }
      end

      def resolve(obj, args, ctx)
        resolve_helper(obj, args, ctx) { super(obj, args, ctx) }
      end

      private

      def resolve_helper(obj, args, ctx)
        raise ::Pundit::NotAuthorizedError unless do_authorize(obj, args, ctx)

        yield
      rescue ::Pundit::NotAuthorizedError
        if @do_raise
          raise GraphQL::ExecutionError, "You're not authorized to do this"
        end
      end

      def do_authorize(root, arguments, context)
        return true unless @authorize
        return @authorize.call(root, arguments, context) if callable? @authorize

        query = infer_query(@authorize)
        record = infer_record(@record, root, arguments, context)
        policy = infer_policy(@policy, record, arguments, context)

        policy.new(context[self.class.current_user], record).public_send query
      end

      def infer_query(auth_value)
        # authorize can be callable, true (for inference) or a policy query
        query = auth_value.equal?(true) ? method_sym : auth_value
        query.to_s + '?'
      end

      def infer_record(record, root, arguments, context)
        # record can be callable, nil (for inference) or just any other value
        if callable?(record)
          record.call(root, arguments, context)
        elsif record.equal?(nil)
          root
        else
          record
        end
      end

      def infer_policy(policy, record, arguments, context)
        # policy can be callable, nil (for inference) or a policy class
        if callable?(policy)
          policy.call(record, arguments, context)
        elsif policy.equal?(nil)
          infer_from = model?(record) ? record.model : record
          ::Pundit::PolicyFinder.new(infer_from).policy!
        else
          policy
        end
      end
    end
  end
end
