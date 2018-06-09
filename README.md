[![Gem](https://img.shields.io/gem/v/graphql-pundit.svg)](https://rubygems.org/gems/graphql-pundit)
[![Build Status](https://travis-ci.org/ontohub/graphql-pundit.svg?branch=master)](https://travis-ci.org/ontohub/graphql-pundit)
[![Coverage Status](https://codecov.io/gh/ontohub/graphql-pundit/branch/master/graph/badge.svg)](https://codecov.io/gh/ontohub/graphql-pundit)
[![Code Climate](https://codeclimate.com/github/ontohub/graphql-pundit/badges/gpa.svg)](https://codeclimate.com/github/ontohub/graphql-pundit)
[![GitHub issues](https://img.shields.io/github/issues/ontohub/graphql-pundit.svg?maxAge=2592000)](https://waffle.io/ontohub/ontohub-backend?source=ontohub%2Fgraphql-pundit)

# GraphQL::Pundit

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'graphql-pundit'
```

And then execute:

```bash
$ bundle
```

## Usage

### Class based API (`graphql-ruby >= 1.8`)

To use `graphql-pundit` with the class based API introduced in `graphql`
version 1.8, the used `Field` class must be changed:

It is recommended to have application-specific base classes, from which the
other types inherit (similar to having an `ApplicationController` from which
all other controllers inherit). That base class can be used to define a
custom field class, on which the new `graphql-pundit` API builds.

```ruby
class BaseObject < GraphQL::Schema::Object
  field_class GraphQL::Pundit::Field
end
```

All other object types now inherit from `BaseObject`, and that is all that is
needed to get `graphql-pundit` working with the class based API.

In case you already use a custom field type, or if you want to use a context
key other than `:current_user` to make your current user available, you can
include `graphql-pundit`'s functionality into your field type:

```ruby
class MyFieldType < GraphQL::Schema::Field
  prepend GraphQL::Pundit::Scope
  prepend GraphQL::Pundit::Authorization

  current_user :me # if the current_user is passed in as context[:me]
end
```

When using this, make sure the order of `prepend`s is correct, as you usually want the authorization to happen **first**, which means that it needs to be `prepend`ed **after** the scopes (if you need them).

#### Usage

```ruby
class Car < BaseObject
  field :trunk, CarContent, null: true,
                            authorize: true
end
```

The above example shows the most basic usage of this gem. The example would
use `CarPolicy#trunk?` for authorizing access to the field, passing in the
parent object (in this case probably a `Car` model).

##### Options

Two styles of declaring fields is supported:

1. the inline style, passing all the options as a hash to the field method
2. the block style

Both styles are presented below side by side.

###### `authorize` and `authorize!`

To use authorization on a field, you **must** pass either the `authorize` or
`authorize!` option. Both options will cause the field to return `nil` if the
access is unauthorized, but `authorize!` will also add an error message (e.g.
for usage with mutations).

`authorize` and `authorize!` can be passed three different things:

```ruby
class User < BaseObject
  # will use the `UserPolicy#display_name?` method
  field :display_name, ..., authorize: true
  field :display_name, ... do
    authorize
  end

  # will use the passed lambda instead of a policy method
  field :password_hash, ..., authorize: ->(obj, args, ctx) { ... }
  field :password_hash, ... do
    authorize ->(obj, args, ctx) { ... }
  end

  # will use the `UserPolicy#personal_info?` method
  field :email, ..., authorize: :personal_info
  field :email, ... do
    authorize :personal_info
  end
end
```

- `true` will trigger the inference mechanism, meaning that the method that will be called on the policy class will be inferred from the (snake_case) field name.
- a lambda function that will be called with the parent object, the arguments of the field and the context object; if the lambda returns a truthy value, authorization succeeds; otherwise (including thrown exceptions), authorization fails
- a string or a symbol that corresponds to the policy method that should be called **minus the "?"**

###### `policy`

`policy` is an optional argument that can also be passed three different values:

```ruby
class User < BaseObject
  # will use the `UserPolicy#display_name?` method (default inference)
  field :display_name, ..., authorize: true, policy: nil
  field :display_name do
    authorize policy: nil
  end

  # will use OtherUserPolicy#password_hash?
  field :password_hash, ...,
                        authorize: true,
                        policy: ->(obj, args, ctx) { OtherUserPolicy }
  field :password_hash, ... do
    authorize policy: ->(obj, args, ctx) { OtherUserPolicy }
  end

  # will use MemberPolicy#email?
  field :email, ..., authorize: true, policy: MemberPolicy
  field :email, ... do
    authorize policy: MemberPolicy
  end
end
```

- `nil` is the default behavior and results in inferring the policy class from the record (see below)
- a lambda function that will be called with the parent object, the arguments of the field and the context object; the return value of this function will be used as the policy class
- an actual policy class

###### `record`

`record` can be used to pass a different value to the policy. Like `policy`,
this argument also can receive three different values:

```ruby
class User < BaseObject
  # will use the parent object
  field :display_name, ..., authorize: true, record: nil
  field :display_name do
    authorize record: nil
  end

  # will use the current user as the record
  field :password_hash, ...,
                        authorize: true,
                        record: ->(obj, args, ctx) { ctx[:current_user] }
  field :password_hash, ... do
    authorize policy: ->(obj, args, ctx) { ctx[:current_user] }
  end

  # will use AccountPolicy#email? with the first account as the record (the policy was inferred from the record class)
  field :email, ..., authorize: true, record: Account.first
  field :email, ... do
    authorize record: Account.first
  end
end
```

- `nil` is again used for the inference; in this case, the parent object is used
- a lambda function, again called with the parent object, the field arguments and the context object; the result will be used as the record
- any other value that will be used as the record

Using `record` can be helpful for e.g. mutations, where you need a value to
initialize the policy with, but for mutations there is no parent object.

###### Combining options

All options can be combined with one another (except `authorize` and `authorize!`; please don't do that). Examples:

```ruby
# MemberPolicy#name? initialized with the parent
field :display_name, ..., authorize: :name,
                          policy: MemberPolicy

# UserPolicy#display_name? initialized with user.account_data
field :display_name, ..., do
  authorize policy: UserPolicy, 
            record: ->(obj, args, ctx) { obj.account_data }
end
```

### Legacy `define` API

The legacy `define` based API will be supported until it is removed from the
`graphql` gem (as planned for version 1.10).

#### Add the authorization middleware

Add the following to your GraphQL schema:

```ruby
MySchema = GraphQL::Schema.define do
  ...
  instrument(:field, GraphQL::Pundit::Instrumenter.new)
  ...
end
```

By default, `ctx[:current_user]` will be used as the user to authorize. To change that behavior, pass a symbol to `GraphQL::Pundit::Instrumenter`. 

```ruby
GraphQL::Pundit::Instrumenter.new(:me) # will use ctx[:me]
```

#### Authorize fields

For each field you want to authorize via Pundit, add the following code to the field definition:

```ruby
field :email do
  authorize # will use UserPolicy#email?
  resolve ...
end
```

By default, this will use the Policy for the parent object (the first argument passed to the resolve proc), checking for `:email?` for the current user. Sometimes, the field name will differ from the policy method name, in which case you can specify it explicitly:

```ruby
field :email do
  authorize :read_email # will use UserPolicy#read_email?
  resolve ...
end
```

Now, in some cases you'll want to use a different policy, or in case of mutations, the passed object might be `nil`:

```ruby
field :createUser
  authorize! :create, policy: User # or User.new; will use UserPolicy#create?
  resolve ...
end
```

This will use the `:create?` method of the `UserPolicy`. You can also pass in objects instead of a class (or symbol), if you wish to authorize the user for the specific object.

If you want to pass a different value to the policy, you can use the keyword argument `record`:

```ruby
field :createUser
  authorize! :create, record: User.new # or User.new; will use UserPolicy#create?
  resolve ...
end
```

You can also pass a `lambda` as a record. This receives the usual three arguments (parent value, arguments, context) and returns the value to be used as a record.

You might have also noticed the use of `authorize!` instead of `authorize` in this example. The difference between the two is this:

- `authorize` will set the field to `nil` if authorization fails
- `authorize!` will set the field to `nil` and add an error to the response if authorization fails

You would normally want to use `authorize` for fields in queries, that only e.g. the owner of something can see, while `authorize!` would be usually used in mutations, where you want to communicate to the client that the operation failed because the user is unauthorized.

If you still need more control over how policies are called, you can pass a lambda to `authorize`:

```ruby
field :email
  authorize ->(obj, args, ctx) { UserPolicy.new(obj, ctx[:me]).private_data?(:email) }
  resolve ...
end
```

If the lambda returns a falsy value or raises a `Pundit::UnauthorizedError` the field will resolve to `nil`, if it returns a truthy value, control will be passed to the resolve function. Of course, this can be used with `authorize!` as well.

#### Scopes

Pundit scopes are supported by using `before_scope` and `after_scope` in the field definition

```ruby
field :posts
  after_scope
  resolve ...
end
```

Passing no arguments to `after_scope` and `before_scope` will infer the policy to use from the value it is passed: `before_scope` is run before `resolve` and will receive the parent object, `after_scope` will be run after `resolve` and receives the output of `resolve`. You can also pass a proc or a policy class to both `_scope`s:

```ruby
field :posts
  before_scope ->(_root, _args, ctx) { Post.where(owner: ctx[:current_user]) }
  resolve ->(posts, args, ctx) { ... }
end
```

```ruby
field :posts
  after_scope PostablePolicy
  resolve ...
end
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/ontohub/graphql-pundit.


## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).

