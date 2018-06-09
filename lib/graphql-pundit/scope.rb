# frozen_string_literal: true

module GraphQL::Pundit
  module Scope
    def initialize(*args, before_scope: nil, after_scope: nil, **kwargs, &block)
      @before_scope = before_scope
      @after_scope = after_scope
      super(*args, **kwargs, &block)
    end

    def before_scope(scope = true)
      @before_scope = scope
    end

    def after_scope(scope = true)
      @after_scope = scope
    end

    def resolve_field(obj, args, ctx)
      before_scope_return = apply_scope(@before_scope, obj, args, ctx)
      field_return = super(before_scope_return, args, ctx)
      apply_scope(@after_scope, field_return, args, ctx)
    end

    private

    def apply_scope(scope, root, arguments, context)
      return root unless scope
      if scope.respond_to?(:call)
        return scope.call(root, arguments, context)
      elsif scope.equal?(true)
        infer_from = if root.respond_to?(:model)
                       root.model
                     else
                       root
                     end
        scope = ::Pundit::PolicyFinder.new(infer_from).policy!
      end
      scope::Scope.new(context[self.class.current_user], root).resolve
    end
  end
end
