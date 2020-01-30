# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'auth field' do |do_raise|
  before do
    [CarPolicy, ChineseCarPolicy].each do |policy|
      allow_any_instance_of(policy).to receive(:name?).and_return(auth_result)
      allow_any_instance_of(policy).to(
        receive(:display_name?).and_return(auth_result)
      )
    end
  end

  context 'authorized' do
    let(:auth_result) { true }

    it 'returns the field value' do
      expect(result).to eq(field_value)
    end
  end

  context 'unauthorized' do
    let(:auth_result) { false }

    if do_raise
      it 'throws an error' do
        expect { result }.to raise_error(GraphQL::ExecutionError)
      end
    else
      it 'returns nil' do
        expect(result).to eq(nil)
      end
    end
  end
end

RSpec.shared_examples 'policies' do |do_raise|
  context 'inferring policy' do
    include_examples 'auth field', do_raise
  end
  context 'using a policy proc' do
    let(:policy) { ->(_, _, _) { ChineseCarPolicy } }
    include_examples 'auth field', do_raise
  end
  context 'using a policy class' do
    let(:policy) { ChineseCarPolicy }
    include_examples 'auth field', do_raise
  end
end

RSpec.shared_examples 'records' do |do_raise|
  context 'inferring the record' do
    include_examples 'policies', do_raise
  end
  context 'using a record proc' do
    let(:record) { ->(_, _, _) { Car.new('Tesla', 'USA') } }
    include_examples 'policies', do_raise
  end
  context 'using an explicit record' do
    let(:record) { Car.new('Tesla', 'USA') }
    include_examples 'policies', do_raise
  end
end

RSpec.shared_examples 'queries' do |do_raise|
  context 'inferring the query' do
    include_examples 'records', do_raise
  end
  context 'using an explicit query' do
    let(:query) { :display_name }
    include_examples 'records', do_raise
  end
  context 'using a proc' do
    let(:query) { ->(_, _, _) { auth_result } }
    include_examples 'records', do_raise
  end
end

RSpec.shared_examples 'auth methods' do
  context 'authorize' do
    let(:do_raise) { false }
    include_examples 'queries'
  end

  context 'authorize!' do
    let(:do_raise) { true }
    include_examples 'queries', true
  end
end

RSpec.describe GraphQL::Pundit::Authorization do
  let(:query) { true }
  let(:record) { nil }
  let(:policy) { nil }
  let(:field_value) { Car.first.name }
  let(:result) { field.resolve(Car.first, {}, spec_context) }

  context 'one-line field definition' do
    let(:field) do
      Field.new(name: :name,
                type: String,
                authorize!: (do_raise ? query : nil),
                authorize: (do_raise ? nil : query),
                record: record,
                policy: policy,
                null: true)
    end

    include_examples 'auth methods'
  end

  context 'block field definition' do
    let(:field) do
      field = Field.new(name: :name,
                        type: String,
                        null: true)
      if do_raise
        field.authorize! query, record: record, policy: policy
      else
        field.authorize query, record: record, policy: policy
      end
      field.to_graphql
    end

    include_examples 'auth methods'
  end
end
