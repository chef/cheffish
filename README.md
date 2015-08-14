# Cheffish

[![Status](https://travis-ci.org/chef/cheffish.svg?branch=master)](https://travis-ci.org/chef/cheffish)
[![Gem Version](https://badge.fury.io/rb/cheffish.svg)](http://badge.fury.io/rb/cheffish)

This library provides a variety of convergent resources for interacting with the Chef Server; along the way, it happens to provide some very useful and sophisticated ways of running Chef resources as recipes in RSpec examples.

**This document may have errors, but it should have enough pointers to get you oriented.**

There are essentially 3 collections here:

## Resource/Provider Pairs for Manipulating Chef Servers

You'd use these in recipes/cookbooks. They are documented on the [main Chef docs site](https://docs.chef.io).

- [chef_acl](https://docs.chef.io/resource_chef_acl.html)
- [chef_client](https://docs.chef.io/resource_chef_client.html)
- [chef_container](https://docs.chef.io/resource_chef_container.html)
- [chef_data_bag](https://docs.chef.io/resource_chef_data_bag.html)
- [chef_data_bag_item](https://docs.chef.io/resource_chef_data_bag_item.html)
- [chef_environment](https://docs.chef.io/resource_chef_environment.html)
- [chef_group](https://docs.chef.io/resource_chef_group.html)
- [chef_mirror](https://docs.chef.io/resource_chef_mirror.html)
- [chef_node](https://docs.chef.io/resource_chef_node.html)
- [chef_organization](https://docs.chef.io/resource_chef_organization.html)
- [chef_resolved_cookbooks](https://docs.chef.io/resource_chef_resolved_cookbooks.html)
- [chef_role](https://docs.chef.io/resource_chef_role.html)
- [chef_user](https://docs.chef.io/resource_chef_user.html)
- [private_key](https://docs.chef.io/resource_private_key.html)
- [public_key](https://docs.chef.io/resource_public_key.html)

## Base/Helper Classes

To support the resource/provider pairs.


## RSpec Support

Most of these RSpec...things were developed for testing the resource/provider pairs above; *however*, you can also `require cheffish/rspec/chef_run_support` for any RSpec `expect`s you'd like, as we do for `chef-provisioning` and its drivers (especially `chef-provisioning-aws`).

The awesomeness here is that instead of instantiating a `run_context` and a `node` and a `resource` as Ruby objects, you can test your resources in an actual recipe:

```ruby
when_the_chef_12_server "exists", organization: 'some-org', server_scope: :context, port: 8900..9000 do
  file "/tmp/something_important.json" do
    content "A resource in its native environment."
  end
end
```

An enclosing context that spins up `chef-zero` (local mode) Chef servers as dictated by `server_scope`. `Chef::Config` will be set up with the appropriate server URLs (see the `with_*` operators below).

`server_scope`:
- `:context`
- `:example` *[default?]*
- ?

`port`:
- port number (8900 is the default)
- port range (server will continue trying up this range until it finds a free port)

```ruby
expect_recipe {
  # unquoted recipe DSL here.
}.to be_truthy    # or write your own matchers.
```

Converges the recipe using `expect()` (parentheses), which tests for a value and **cannot** be used with `raise_error`.

```ruby
expect_converge {
  # unquoted recipe DSL here.
}.to raise_error(ArgumentException)
```

Converges the recipe using `expect{ }` (curly brackets), which wraps the block in a `begin..rescue..end` to detect when the block raises an exception; hence, this is **only** for `raise_error`.

The blocks for the following appear to be mostly optional: what they actually do is set the `Chef::Config` variable in the name to the given value, and if you provide a block, the change is scoped to that block. Probably this would be clearer if it were aliased to (and preferring) `using` rather than `with`.

- with_chef_server(server_url, options = {}, &block)
- with_chef_local_server(options, &block)
- with_chef_environment(name, &block)
- with_chef_data_bag_item_encryption(encryption_options, &block)
- with_chef_data_bag(name)
  - Takes a block, though this is not noted in the method signature.



get_private_key(name)


### RSpec matchers

These are used with `expect_recipe` or `expect_converge`:

```ruby
expect_recipe {
  file "/tmp/a_file.json" do
    content "Very important content."
  end
}.to be_idempotent.and emit_no_warnings_or_errors
```

`be_idempotent`

- Runs the provided recipe *again* (`expect_(recipe|converge)` ran it the first time) and asks the Chef run if it updated anything (using `updated?`, which appears to be defined on `Chef::Resource` instead of `Chef::Client`, so there's some clarification to be done there); the matcher is satisfied if the answer is "no."


`emit_no_warnings_or_errors`

- Greps the Chef client run's log output for WARN/ERROR lines; matcher is satisfied if there aren't any.

`have_updated`

- Sifts the recipe's event stream(!) to determine if any resources were updated; matcher is satisfied is the answer is "yes."
- This is *not* the opposite of `be_idempotent`.

`partially_match`

- TBD
