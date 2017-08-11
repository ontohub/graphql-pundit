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
    context 'with name' do
      context 'with record' do
        let(:field) do
          subj = subject
          GraphQL::Field.define(type: 'String') do
            name :notTest
            if error
              authorize! :test, subj
            else
              authorize :test, subj
            end
            resolve ->(obj, _args, _ctx) { obj.to_s }
          end
        end
        let(:result) { instrumented_field.resolve(Test.new('pass'), {}, {}) }

        include_examples 'an authorizing field', error
      end

      context 'without record' do
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

RSpec.describe GraphQL::Pundit::Instrumenter do
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
