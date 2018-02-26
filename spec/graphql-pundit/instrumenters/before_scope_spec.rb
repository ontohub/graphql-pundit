# frozen_string_literal: true

require 'spec_helper'

class ScopeTest
  def initialize(value)
    @value = value
  end

  def where(&block)
    ScopeTest.new(@value.select(&block))
  end

  def to_a
    @value
  end
end

class ScopeTestDataset < ScopeTest
  def model
    ScopeTest
  end
end

class ScopeTestPolicy
  class Scope
    attr_reader :scope

    def initialize(_, scope)
      @scope = scope
    end

    def resolve
      scope.where { |e| e.to_i < 20 }
    end
  end

  def initialize(_, _); end

  def test?
    nil
  end
end

RSpec.describe GraphQL::Pundit::Instrumenters::BeforeScope do
  let(:instrumenter) { GraphQL::Pundit::Instrumenter.new }
  let(:instrumented_field) { instrumenter.instrument(nil, field) }
  let(:result) { instrumented_field.resolve(subject, {}, {}) }

  subject { ScopeTest.new([1, 2, 3, 22, 48]) }

  context 'without authorization' do
    context 'inferred scope' do
      let(:field) do
        GraphQL::Field.define(type: 'String') do
          name :notTest
          before_scope
          resolve ->(obj, _args, _ctx) { obj.to_a }
        end
      end

      it 'filters the list' do
        expect(result).to match_array([1, 2, 3])
      end

      context 'scope from model' do
        subject { ScopeTestDataset.new([1, 2, 3, 22, 48]) }
        let(:field) do
          GraphQL::Field.define(type: 'String') do
            name :notTest
            before_scope
            resolve ->(obj, _args, _ctx) { obj.to_a }
          end
        end

        it 'filters the list' do
          expect(result).to match_array([1, 2, 3])
        end
      end
    end

    context 'explicit scope proc' do
      let(:field) do
        GraphQL::Field.define(type: 'String') do
          name :notTest
          before_scope ->(scope, _args, _ctx) { scope.where { |e| e > 20 } }
          resolve ->(obj, _args, _ctx) { obj.to_a }
        end
      end

      it 'filters the list' do
        expect(result).to match_array([22, 48])
      end
    end

    context 'explicit scope class' do
      let(:field) do
        GraphQL::Field.define(type: 'String') do
          name :notTest
          before_scope ScopeTestPolicy
          resolve ->(obj, _args, _ctx) { obj.to_a }
        end
      end

      it 'filters the list' do
        expect(result).to match_array([1, 2, 3])
      end
    end
  end

  context 'with authorization' do
    context 'inferred scope' do
      let(:field) do
        GraphQL::Field.define(type: 'String') do
          name :test
          authorize
          before_scope
          resolve ->(obj, _args, _ctx) { obj.to_a }
        end
      end

      it 'returns nil' do
        expect(result).to eq(nil)
      end

      context 'scope from model' do
        subject { ScopeTestDataset.new([1, 2, 3, 22, 48]) }
        let(:field) do
          GraphQL::Field.define(type: 'String') do
            name :test
            authorize policy: :scope_test
            before_scope
            resolve ->(obj, _args, _ctx) { obj.to_a }
          end
        end

        it 'returns nil' do
          expect(result).to eq(nil)
        end
      end
    end

    context 'explicit scope proc' do
      let(:field) do
        GraphQL::Field.define(type: 'String') do
          name :test
          authorize
          before_scope ->(scope, _args, _ctx) { scope.where { |e| e > 20 } }
          resolve ->(obj, _args, _ctx) { obj.to_a }
        end
      end

      it 'returns nil' do
        expect(result).to eq(nil)
      end
    end

    context 'explicit scope class' do
      let(:field) do
        GraphQL::Field.define(type: 'String') do
          name :test
          authorize
          before_scope ScopeTestPolicy
          resolve ->(obj, _args, _ctx) { obj.to_a }
        end
      end

      it 'returns nil' do
        expect(result).to eq(nil)
      end
    end
  end

  context 'invalid scope argument' do
    let(:field) do
      GraphQL::Field.define(type: 'String') do
        name :test
        authorize
        before_scope 'invalid value'
        resolve ->(obj, _args, _ctx) { obj.to_a }
      end
    end

    it 'raises an error' do
      expect { result }.to raise_error(ArgumentError)
    end
  end
end
