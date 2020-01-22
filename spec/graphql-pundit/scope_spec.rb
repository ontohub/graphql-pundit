# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'before_scope' do |with_authorization|
  if with_authorization
    it 'returns nil' do
      expect(result).to eq(nil)
    end
  else
    it 'calls the scope' do
      expect(result).to match_array(expected_result)
    end
  end
end

RSpec.shared_examples 'after_scope' do |with_authorization|
  if with_authorization
    it 'returns nil' do
      expect(result).to eq(nil)
    end
  else
    it 'calls the scope' do
      expect(result).to match_array(expected_result)
    end
  end
end

RSpec.shared_examples 'authorizing scopes' do |with_authorization|
  let(:authorize) { true } if with_authorization

  context 'before_scope' do
    let(:resolve) { :names }

    context 'inferred scope' do
      let(:before_scope) { true }
      let(:expected_result) do
        ['Volkswagen Group', 'Daimler', 'BMW']
      end
      include_examples 'before_scope', with_authorization
    end

    context 'explicit scope' do
      let(:before_scope) do
        ->(scope, _, _) { scope.where { |c| c.country == 'Japan' } }
      end
      let(:expected_result) do
        %w(Honda Mazda Nissan Suzuki Toyota)
      end
      include_examples 'before_scope', with_authorization
    end

    context 'explicit policy class' do
      let(:before_scope) { ChineseCarPolicy }
      let(:expected_result) do
        ['BAIC', 'Changan', 'Dongfeng Motor', 'Geely', 'Great Wall', 'SAIC']
      end
      include_examples 'before_scope', with_authorization
    end
  end

  context 'after_scope' do
    let(:resolve) { :longer_then_five }

    context 'inferred scope' do
      let(:scope_class) do
        Class.new(CarPolicy::Scope) do
          def resolve
            scope.where { |c| c.country == 'Germany' }.to_a.map(&:name)
          end
        end
      end
      let(:after_scope) { true }
      let(:expected_result) do
        ['Volkswagen Group', 'Daimler']
      end

      before do
        stub_const('CarPolicy::Scope', scope_class)
      end

      include_examples 'after_scope', with_authorization
    end

    context 'explicit scope' do
      let(:after_scope) do
        lambda do |scope, _, _|
          scope.where { |c| c.country == 'Japan' }.to_a.map(&:name)
        end
      end
      let(:expected_result) do
        %w(Nissan Suzuki Toyota)
      end
      include_examples 'after_scope', with_authorization
    end

    context 'explicit policy class' do
      let(:scope_class) do
        Class.new(CarPolicy::Scope) do
          def resolve
            scope.where { |c| c.country == 'China' }.to_a.map(&:name)
          end
        end
      end

      let(:after_scope) { ChineseCarPolicy }
      let(:expected_result) do
        ['Changan', 'Dongfeng Motor', 'Great Wall']
      end

      before do
        stub_const('ChineseCarPolicy::Scope', scope_class)
      end

      include_examples 'after_scope', with_authorization
    end
  end
end

RSpec.describe GraphQL::Pundit::Scope do
  let(:before_scope) { nil }
  let(:after_scope) { nil }
  let(:authorize) { nil }
  let(:result) { field.resolve(Car, {}, spec_context) }
  context 'one-line field definition' do
    let(:field) do
      Field.new(name: :name,
                type: [String],
                authorize: authorize,
                before_scope: before_scope,
                after_scope: after_scope,
                null: true,
                resolver_method: resolve)
    end

    context 'with failing authorization' do
      include_examples 'authorizing scopes', true
    end
    context 'without authorization' do
      include_examples 'authorizing scopes', false
    end
  end

  context 'block field definition' do
    let(:field) do
      field = Field.new(name: :name,
                        type: [String],
                        authorize: authorize,
                        null: true,
                        resolver_method: resolve)
      field.before_scope before_scope
      field.after_scope after_scope
      field
    end

    context 'with failing authorization' do
      include_examples 'authorizing scopes', true
    end
    context 'without authorization' do
      include_examples 'authorizing scopes', false
    end
  end
end
