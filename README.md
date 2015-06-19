# Cheffish

This library provides a variety of convergent resources for interacting with the Chef Server; along the way, it happens to provide some very useful and sophisticated ways of running Chef resources as recipes in RSpec examples.

**This document may have errors, but it should have enough pointers to get you oriented.**

There are essentially 3 collections here:

## Resource/Provider Pairs for Manipulating Chef Servers

You'd use these in cookbooks.

- chef_acl
- chef_client
- chef_container
- chef_data_bag
- chef_data_bag_item
- chef_environment
- chef_group
- chef_mirror
- chef_node
- chef_organization
- chef_resolved_cookbooks
- chef_role
- chef_user
- private_key
- public_key

## Base/Helper Classes

To support the resource/provider pairs.


## RSpec Support

Most of these were developed for testing the resource/provider pairs above; *however*, you can also `require cheffish/rspec/chef_run_support` for any RSpec `expect`s you'd like, as we do for `chef-provisioning` and its drivers (especially `chef-provisioning-aws`).

```ruby
when_the_chef_12_server "exists", organization: 'some-org', server_scope: :context, port: 8900..9000 do
  # examples here.
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

Converges the recipe using `expect()` (parentheses), which tests for a value and cannot be used with `raise_error`.

```ruby
expect_converge {
  # unquoted recipe DSL here.
}.to be_truthy    # or write your own matchers.
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

