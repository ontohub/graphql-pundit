# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GraphQL::Pundit::Scope do
  let(:result) { field.resolve_field(subject, {}, {}) }

  subject { ScopeTest.new([1, 2, 3, 22, 48]) }

  context 'without authorization' do
    context 'inferred scope' do
      let(:field) do
        Field.new(name: :to_a,
                  type: String,
                  before_scope: true,
                  null: true)
      end

      it 'filters the list' do
        expect(result).to match_array([1, 2, 3])
      end

      context 'scope from model' do
        subject { ScopeTestDataset.new([1, 2, 3, 22, 48]) }

        it 'filters the list' do
          expect(result).to match_array([1, 2, 3])
        end
      end
    end

    context 'explicit scope proc' do
      let(:field) do
        Field.new(name: :to_a,
                  type: String,
                  before_scope: ->(scope, _args, _ctx) { scope.where { |e| e > 20 } },
                  null: true)
      end

      it 'filters the list' do
        expect(result).to match_array([22, 48])
      end
    end

    context 'explicit scope class' do
      let(:field) do
        Field.new(name: :to_a,
                  type: String,
                  before_scope: ScopeTestPolicy,
                  null: true)
      end

      it 'filters the list' do
        expect(result).to match_array([1, 2, 3])
      end
    end
  end

  context 'with authorization' do
    context 'inferred scope' do
      let(:field) do
        Field.new(name: :to_a,
                  type: String,
                  before_scope: true,
                  authorize: true,
                  null: true)
      end

      it 'returns nil' do
        expect(result).to eq(nil)
      end

      context 'scope from model' do
        subject { ScopeTestDataset.new([1, 2, 3, 22, 48]) }
        let(:field) do
          Field.new(name: :to_a,
                    type: String,
                    before_scope: true,
                    authorize: true,
                    policy: ScopeTestPolicy,
                    null: true)
        end

        it 'returns nil' do
          expect(result).to eq(nil)
        end
      end
    end

    context 'explicit scope proc' do
      let(:field) do
        Field.new(name: :to_a,
                  type: String,
                  before_scope: ->(scope, _args, _ctx) { scope.where { |e| e > 20 } },
                  authorize: true,
                  null: true)
      end

      it 'returns nil' do
        expect(result).to eq(nil)
      end
    end

    context 'explicit scope class' do
      let(:field) do
        Field.new(name: :to_a,
                  type: String,
                  before_scope: ScopeTestPolicy,
                  authorize: true,
                  null: true)
      end

      it 'returns nil' do
        expect(result).to eq(nil)
      end
    end
  end
end
