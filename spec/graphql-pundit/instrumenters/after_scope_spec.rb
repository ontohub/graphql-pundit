# frozen_string_literal: true

require 'spec_helper'

class User
  attr_reader :name, :posts

  def initialize(name, posts)
    @name = name
    @posts = posts
  end
end

class Post
  attr_reader :title, :text, :author, :published

  def initialize(title, text, author, published = true)
    @title = title
    @text = text
    @author = author
    @published = published
  end
end

class PostDataset
  attr_reader :values

  def initialize(values)
    @values = values
  end

  def model
    Post
  end

  def to_a
    values
  end

  def map(&block)
    values.map(&block)
  end

  def where(&block)
    PostDataset.new(values.select(&block))
  end

  def select(&block)
    where(&block)
  end
end

class UserPolicy
  attr_reader :current_user, :user

  def initialize(current_user, user)
    @current_user = current_user
    @user = user
  end

  def posts?
    false
  end

  def last_post?
    false
  end
end

class PostPolicy
  class Scope
    attr_reader :scope

    def initialize(_, scope)
      @scope = scope
    end

    def resolve
      if scope.respond_to?(:select)
        scope.select(&:published)
      else
        scope
      end
    end
  end
end

RSpec.describe GraphQL::Pundit::Instrumenters::AfterScope do
  let(:instrumenter) { GraphQL::Pundit::Instrumenter.new }
  let(:instrumented_field) { instrumenter.instrument(nil, field) }
  let(:result) { instrumented_field.resolve(subject, {}, {}) }

  subject do
    User.new('Ada', [
               Post.new('First Post', 'This is the first post', 'ada'),
               Post.new('Second Post', 'This is the second post', 'ada', false),
             ])
  end

  context 'without authorization' do
    context 'inferred scope' do
      subject do
        dataset = PostDataset.new(
          [
            Post.new('First Post', 'This is the first post', 'ada'),
            Post.new('Second Post', 'This is the second post', 'ada', false),
          ]
        )
        User.new('Ada', dataset)
      end

      context 'scope from model' do
        let(:field) do
          GraphQL::Field.define(type: '[Post!]') do
            name :posts
            after_scope
          end
        end

        it 'filters the list' do
          expect(result.map(&:published)).to match_array([true])
        end
      end

      context 'scope from other' do
        let(:field) do
          GraphQL::Field.define(type: 'Post') do
            name :last_post
            after_scope
            resolve ->(user, _args, _ctx) { user.posts.to_a.last }
          end
        end

        it 'filters the list' do
          expect(result.published).to be_falsy
        end
      end
    end

    context 'explicit scope proc' do
      let(:field) do
        GraphQL::Field.define(type: '[Post!]') do
          name :unpublished_posts
          property :posts
          after_scope ->(posts, _args, _ctx) { posts.reject(&:published) }
        end
      end

      it 'filters the list' do
        expect(result.map(&:published)).to match_array([false])
      end
    end

    context 'explicit scope class' do
      let(:field) do
        GraphQL::Field.define(type: '[Post!]') do
          name :published_posts
          property :posts
          after_scope PostPolicy
        end
      end

      it 'filters the list' do
        expect(result.map(&:published)).to match_array([true])
      end
    end
  end

  context 'with authorization' do
    context 'inferred scope' do
      context 'scope from model' do
        let(:field) do
          GraphQL::Field.define(type: '[Post!]') do
            name :posts
            authorize
            after_scope
          end
        end

        it 'returns nil' do
          expect(result).to eq(nil)
        end
      end

      context 'scope from other' do
        let(:field) do
          GraphQL::Field.define(type: 'Post') do
            name :last_post
            authorize
            after_scope
            resolve ->(user, _args, _ctx) { user.posts.to_a.last }
          end
        end

        it 'filters the list' do
          expect(result).to eq(nil)
        end
      end
    end

    context 'explicit scope proc' do
      let(:field) do
        GraphQL::Field.define(type: '[Post!]') do
          name :posts
          authorize
          after_scope ->(posts, _args, _ctx) { posts.select(&:published) }
        end
      end

      it 'returns nil' do
        expect(result).to eq(nil)
      end
    end

    context 'explicit scope class' do
      let(:field) do
        GraphQL::Field.define(type: '[Post!]') do
          name :posts
          authorize
          after_scope PostPolicy
        end
      end

      it 'returns nil' do
        expect(result).to eq(nil)
      end
    end
  end

  context 'invalid scope argument' do
    let(:field) do
      GraphQL::Field.define(type: '[Post!]') do
        name :posts
        authorize
        after_scope 'invalid value'
      end
    end

    it 'raises an error' do
      expect { result }.to raise_error(ArgumentError)
    end
  end
end
