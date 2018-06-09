# frozen_string_literal: true

module GraphQL::Pundit
  module Authorization
    module ClassMethods
      def current_user(current_user = nil)
        return class_variable_get(:@@current_user) unless current_user
        class_variable_set(:@@current_user, current_user)
      end
    end

    def self.prepended(base)
      @@current_user = :current_user
      base.extend(ClassMethods)
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
      raise ::Pundit::NotAuthorizedError unless do_authorize(obj, args, ctx)
      super(obj, args, ctx)
    rescue ::Pundit::NotAuthorizedError
      if @do_raise
        raise GraphQL::ExecutionError, "You're not authorized to do this"
      end
    end

    private

    def do_authorize(root, arguments, context)
      return true unless @authorize
      return @authorize.call(root, arguments, context) if callable?(@authorize)

      # authorize can be callable, true (for inference) or a policy query
      @authorize = method_sym if @authorize.equal?(true)

      # record can be callable, nil (for inference) or just any other value
      if callable?(@record)
        @record = @record.call(root, arguments, context)
      elsif @record.equal?(nil)
        @record = root
      end

      # policy can be callable, nil (for inference) or a policy class
      if callable?(@policy)
        @policy = @policy.call(@record, arguments, context)
      elsif @policy.equal?(nil)
        @policy = ::Pundit::PolicyFinder.new(@record).policy!
      end
      @policy.new(context[self.class.current_user], @record).public_send(query)
    end

    def callable?(thing)
      thing.respond_to?(:call)
    end

    def query
      @authorize.to_s + '?'
    end
  end
end
