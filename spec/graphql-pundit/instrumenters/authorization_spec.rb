# frozen_string_literal: true

require 'spec_helper'

class Test
  def initialize(value)
    @value = value
  end

  def to_s
    @value.to_s
  end
end

class TestPolicy
  def initialize(_, value)
    @value = value
  end

  def test?
    @value.to_s == 'pass'
  end
end

RSpec.shared_examples 'an authorizing field' do |error|
  context 'Authorized' do
    subject { pass_test }
    it 'returns the value' do
      expect(result).to eq(subject.to_s)
    end
  end

  context 'Unauthorized' do
    subject { fail_test }
    if error
      it 'raises an execution error' do
        expect { result }.to raise_error(GraphQL::ExecutionError)
      end
    else
      it 'returns nil' do
        expect(result).to eq(nil)
      end
    end
  end
end

RSpec.shared_examples 'field with authorization' do |error|
  context 'with query' do
    context 'with record' do
      context 'direct record' do
        context 'with policy' do
          let(:field) do
            record = subject.to_s
            GraphQL::Field.define(type: 'String') do
              name :notTest
              if error
                authorize! :test, policy: :test, record: record
              else
                authorize :test, policy: :test, record: record
              end
              resolve ->(obj, _args, _ctx) { obj.to_s }
            end
          end
          let(:result) { instrumented_field.resolve(Test.new('pass'), {}, {}) }

          include_examples 'an authorizing field', error
        end

        context 'without policy' do
          let(:field) do
            record = subject
            GraphQL::Field.define(type: 'String') do
              name :notTest
              if error
                authorize! :test, record: record
              else
                authorize :test, record: record
              end
              resolve ->(obj, _args, _ctx) { obj.to_s }
            end
          end
          let(:result) { instrumented_field.resolve(Test.new('pass'), {}, {}) }

          include_examples 'an authorizing field', error
        end
      end

      context 'lambda record' do
        context 'with policy' do
          let(:field) do
            record = ->(_obj, _arguments, ctx) { ctx[:subject].to_s }
            GraphQL::Field.define(type: 'String') do
              name :notTest
              if error
                authorize! :test, policy: :test, record: record
              else
                authorize :test, policy: :test, record: record
              end
              resolve ->(obj, _args, _ctx) { obj.to_s }
            end
          end
          let(:result) do
            instrumented_field.resolve(Test.new('pass'), {}, subject: subject)
          end

          include_examples 'an authorizing field', error
        end

        context 'without policy' do
          let(:field) do
            record = ->(_obj, _arguments, ctx) { ctx[:subject] }
            GraphQL::Field.define(type: 'String') do
              name :notTest
              if error
                authorize! :test, record: record
              else
                authorize :test, record: record
              end
              resolve ->(obj, _args, _ctx) { obj.to_s }
            end
          end
          let(:result) do
            instrumented_field.resolve(Test.new('pass'), {}, subject: subject)
          end

          include_examples 'an authorizing field', error
        end
      end
    end

    context 'without record' do
      context 'with policy' do
        let(:field) do
          GraphQL::Field.define(type: 'String') do
            name :notTest
            if error
              authorize! :test, policy: :test
            else
              authorize :test, policy: :test
            end
            resolve ->(obj, _args, _ctx) { obj.to_s }
          end
        end

        include_examples 'an authorizing field', error
      end

      context 'without policy' do
        let(:field) do
          GraphQL::Field.define(type: 'String') do
            name :notTest
            if error
              authorize! :test
            else
              authorize :test
            end
            resolve ->(obj, _args, _ctx) { obj.to_s }
          end
        end

        include_examples 'an authorizing field', error
      end
    end
  end

  context 'with proc' do
    let(:field) do
      GraphQL::Field.define(type: 'String') do
        name :notTest
        if error
          authorize! ->(obj, _args, _ctx) { TestPolicy.new(nil, obj).test? }
        else
          authorize ->(obj, _args, _ctx) { TestPolicy.new(nil, obj).test? }
        end
        resolve ->(obj, _args, _ctx) { obj.to_s }
      end
    end

    include_examples 'an authorizing field', error
  end

  context 'without query' do
    let(:field) do
      GraphQL::Field.define(type: 'String') do
        name :test
        if error
          authorize!
        else
          authorize
        end
        resolve ->(obj, _args, _ctx) { obj.to_s }
      end
    end

    include_examples 'an authorizing field', error
  end
end

RSpec.describe GraphQL::Pundit::Instrumenters::Authorization do
  let(:instrumenter) { GraphQL::Pundit::Instrumenter.new }
  let(:instrumented_field) { instrumenter.instrument(nil, field) }
  let(:fail_test) { Test.new(:fail) }
  let(:pass_test) { Test.new(:pass) }
  let(:result) { instrumented_field.resolve(subject, {}, {}) }

  context 'authorize' do
    include_examples 'field with authorization', false
  end

  context 'authorize!' do
    include_examples 'field with authorization', true
  end
end
