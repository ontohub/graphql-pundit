require 'graphql-pundit/instrumenters/authorization'

module GraphQL::Pundit
  module Authorization
    def initialize(*args, authorize: nil, record: nil, policy: nil, **kwargs, &block)
      authorize_bang = kwargs.delete(:authorize!) # authorize! is not a valid variable name
      @record = record if record
      @policy = policy if policy
      @authorize = authorize_bang || authorize
      @do_raise = !!authorize_bang
      super(*args, **kwargs, &block)
    end

    def authorize(query = true, record:, policy:)
      @authorize = query
      @record = record if record
      @policy = policy if policy
    end

    def authorize!(query = true, record:, policy:)
      @do_raise = true
      authorize(query, record: record, policy: policy)
    end

    def resolve_field(obj, args, ctx)
      raise ::Pundit::NotAuthorizedError unless do_authorize(obj, args, ctx)
      super(obj, args, ctx)
    rescue ::Pundit::NotAuthorizedError
      if @do_raise
        raise GraphQL::ExecutionError, "You're not authorized to do this"
      end
    end

    private

    def do_authorize(root, arguments, context)
      case # @authorize can be true, callable or a symbol/string
      when @authorize.respond_to?(:call)
        return @authorize.call(root, arguments, context)
      when @authorize.equal?(true)
        @authorize = method_sym
      end

      case # record can be nil, callable or anything else
      when @record.respond_to?(:call)
        @record = @record.call(root, arguments, context)
      when @record.equal?(nil)
        @record = root
      end

      case # policy can be nil, callable or a policy class
      when @policy.respond_to?(:call)
        @policy = @policy.call(root, arguments, context)
      when @policy.equal?(nil)
        @policy = ::Pundit::PolicyFinder.new(@record).policy!()
      end
      @policy.new(context[:current_user], @record).public_send(query)
    end

    def query
      @authorize.to_s + '?'
    end
  end
end
