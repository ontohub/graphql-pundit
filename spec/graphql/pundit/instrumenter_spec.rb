require_relative "../../spec_helper"

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

  def create?
    @value.to_s == "pass"
  end
end

RSpec.describe GraphQL::Pundit::Instrumenter do
  let(:instrumenter) { GraphQL::Pundit::Instrumenter.new }
  let(:instrumented_field) { instrumenter.instrument(nil, field) }
  let(:fail) { Test.new(:fail) }
  let(:pass) { Test.new(:pass) }
  let(:result) { instrumented_field.resolve(subject, {}, {})}

  context 'authorize' do
    let(:field) do
      GraphQL::Field.define(type: "String") do
        name "TestField"
        authorize :create
        resolve ->(obj, args, ctx) { obj.to_s }
      end
    end

    context 'Authorized' do
      subject { pass }
      it 'returns the value' do
        expect(result).to eq("pass")
      end
    end

    context 'Unauthorized' do
      subject { fail }
      it 'returns nil' do
        expect(result).to eq(nil)
      end
    end
  end

  context 'authorize!' do
    let(:field) do
      GraphQL::Field.define(type: "String") do
        name "TestField"
        authorize! :create
        resolve ->(obj, args, ctx) { obj.to_s }
      end
    end

    context 'Authorized' do
      subject { pass }
      it 'returns the value' do
        expect(result).to eq("pass")
      end
    end

    context 'Unauthorized' do
      subject { fail }
      it 'raises an execution error' do
        expect { result }.to raise_error(GraphQL::ExecutionError)
      end
    end
  end
end
