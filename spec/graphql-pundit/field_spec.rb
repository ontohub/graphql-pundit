# frozen_string_literal: true

require 'spec_helper'

Field = GraphQL::Pundit::Field

RSpec.shared_examples 'auth field' do |do_raise|
  before do
    [TestPolicy, AlternativeTestPolicy].each do |policy|
      allow_any_instance_of(policy).to receive(:to_s?).and_return(auth_result)
      allow_any_instance_of(policy).to receive(:test?).and_return(auth_result)
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
    let(:policy) { ->(_, _, _) { AlternativeTestPolicy } }
    include_examples 'auth field', do_raise
  end
  context 'using a policy class' do
    let(:policy) { AlternativeTestPolicy }
    include_examples 'auth field', do_raise
  end
end

RSpec.shared_examples 'records' do |do_raise|
  context 'inferring the record' do
    include_examples 'policies', do_raise
  end
  context 'using a record proc' do
    let(:record) { ->(_, _, _) { Test.new('alternative record') } }
    include_examples 'policies', do_raise
  end
  context 'using an explicit record' do
    let(:record) { Test.new('alternative record') }
    include_examples 'policies', do_raise
  end
end

RSpec.shared_examples 'queries' do |do_raise|
  context 'inferring the query' do
    include_examples 'records', do_raise
  end
  context 'using an explicit query' do
    let(:query) { :test }
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

RSpec.describe GraphQL::Pundit::Field do
  let(:query) { true }
  let(:record) { nil }
  let(:policy) { nil }
  let(:field_value) { 'pass' }
  let(:result) { field.resolve_field(Test.new(field_value), {}, {}) }

  context 'one-line field definition' do
    let(:field) do
      Field.new(name: :to_s,
                type: String,
                authorize!: (do_raise ? query : nil),
                authorize: (do_raise ? nil : query),
                record: record,
                policy: policy,
                resolve: ->(obj, _, _) { obj.to_s },
                null: true)
    end

    include_examples 'auth methods'
  end

  context 'block field definition' do
    let(:field) do
      field = Field.new(name: :to_s,
                        type: String,
                        resolve: ->(obj, _, _) { obj.to_s },
                        null: true)
      if do_raise
        field.authorize! query, record: record, policy: policy
      else
        field.authorize query, record: record, policy: policy
      end
      field
    end

    include_examples 'auth methods'
  end
end
