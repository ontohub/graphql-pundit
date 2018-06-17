# frozen_string_literal: true

module GraphQL
  module Pundit
    # Common methods used for authorization and scopes
    module Common
      # Class methods to be included in the Field class
      module ClassMethods
        def current_user(current_user = nil)
          return @current_user unless current_user
          @current_user = current_user
        end
      end

      def self.included(base)
        @current_user = :current_user
        base.extend(ClassMethods)
      end

      def callable?(thing)
        thing.respond_to?(:call)
      end

      def model?(thing)
        thing.respond_to?(:model)
      end
    end
  end
end
