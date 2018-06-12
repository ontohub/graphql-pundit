# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GraphQL::Pundit::Scope do
  let(:result) { field.resolve_field(subject, {}, {}) }

  subject { ScopeTest.new([1, 2, 3, 22, 48]) }

  context 'one-line field definition' do
    let(:field) do
      Field.new(name: :to_a,
                type: String,
                before_scope: before_scope,
                authorize: authorize,
                null: true)
    end

    context 'without authorization' do
      let(:authorize) { nil }
      context 'inferred scope' do
        let(:before_scope) { true }
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
        let(:before_scope) do
          lambda do |scope, _args, _ctx|
            scope.where { |e| e > 20 }
          end
        end

        it 'filters the list' do
          expect(result).to match_array([22, 48])
        end
      end

      context 'explicit scope class' do
        let(:before_scope) do
          ScopeTestPolicy
        end

        it 'filters the list' do
          expect(result).to match_array([1, 2, 3])
        end
      end
    end

    context 'with authorization' do
      let(:authorize) { true }
      context 'inferred scope' do
        let(:before_scope) { true }

        it 'returns nil' do
          expect(result).to eq(nil)
        end

        context 'scope from model' do
          subject { ScopeTestDataset.new([1, 2, 3, 22, 48]) }

          it 'returns nil' do
            expect(result).to eq(nil)
          end
        end
      end

      context 'explicit scope proc' do
        let(:before_scope) do
          lambda do |scope, _args, _ctx|
            # :nocov:
            # This is supposed to not be run
            scope.where { |e| e > 20 }
            # :nocov:
          end
        end

        it 'returns nil' do
          expect(result).to eq(nil)
        end
      end

      context 'explicit scope class' do
        let(:before_scope) do
          ScopeTestPolicy
        end

        it 'returns nil' do
          expect(result).to eq(nil)
        end
      end
    end
  end
end
