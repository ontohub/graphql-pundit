# frozen_string_literal: true

RSpec.describe GraphQL::Pundit::Common do
  describe 'current_user' do
    it 'sets the correct value' do
      klass = Class.new do
        include GraphQL::Pundit::Common
      end
      klass.current_user :me
      expect(klass.current_user).to eq(:me)
    end
  end
end
