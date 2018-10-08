# frozen_string_literal: true

require 'graphql-pundit/common'

module GraphQL
  module Pundit
    # Scope methods to be included in the used Field class
    module Scope
      def self.prepended(base)
        base.include(GraphQL::Pundit::Common)
      end

      def initialize(*args, before_scope: nil,
                            after_scope: nil,
                            **kwargs, &block)
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
        before_scope_return = apply_pundit_scope(@before_scope, obj, args, ctx)
        field_return = super(before_scope_return, args, ctx)
        apply_pundit_scope(@after_scope, field_return, args, ctx)
      end

      private

      def apply_pundit_scope(scope, root, arguments, context)
        return root unless scope
        return scope.call(root, arguments, context) if scope.respond_to?(:call)

        scope = infer_scope(root) if scope.equal?(true)
        scope::Scope.new(context[self.class.current_user], root).resolve
      end

      def infer_scope(root)
        infer_from = model?(root) ? root.model : root
        ::Pundit::PolicyFinder.new(infer_from).policy!
      end
    end
  end
end
