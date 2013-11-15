# Cheffish #

This library lets you manipulate Chef in Chef.

# Description #

Cheffish extends the Chef recipe DSL for managing infrastructure resources programatically from a machine with the proper client permissions (such as a workstation). It provides Resources for managing the content on the Chef Server and for the lifecycle of nodes in an ordered, idempotent fashion. Any commands available through  `knife` should eventually be available through Cheffish and it has access to all of the Chef Resources as well.

## Example ##

Here is an example of a Cheffish recipe.

````ruby
['mysql', 'myapp'].each do |cb|
  cookbook cb do
    action :upload
  end
end

['preprod', 'production'] do |env|
  environment env do
    action :upload
  end
end

['database', 'database-test', 'myapp'].each do |rl|
  role rl do
    action :upload
  end
end

instance 'foo.bar.com' do
  user 'ubuntu'
  password 'passw0rd'
  sudo true
  environment 'preprod'
  run_list 'role[database]'
  action :bootstrap
end

openstack 'os-preprod' do
  count 5
  flavor '2'
  image '125'
  keypair 'matt'
  sudo true
  environment 'preprod'
  run_list 'role[database-test]'
  action :nothing
  subscribes :create, 'node[foo.bar.com]'
end

instance 'foo.bar.com' do
    environment 'production'
    role 'myapp'
    action :converge
end

openstack 'os-preprod' do
    action :delete
end
````

This recipe uses the `cookbook`, `environment`, `role`, `instance` and `openstack` Resources. It uploads the cookbooks, environments and roles and then bootstraps the machine instance 'foo.bar.com' with the `run_list` of 'role['database']'. Next it creates 5 OpenStack instances with the `run_list` of 'role[database-test]'. 'foo.bar.com' is then moved to the 'production' `environment`, with the `run_list` appended with the 'myapp' `role` and it then runs the `chef-client`. The OpenStack instances with the label of 'os-preprod' are then deleted. The assumption is that the recipe is called from our Chef repository and the `knife.rb` is providing our Chef server and OpenStack settings. If this recipe is called again, the 'foo.bar.com' machine instance will run the `chef-client` but no other Resources will perform actions.

# Usage #

Cheffish is called... how? Where do recipes and cookbooks live? What CLI options should it have? How are cheffish run lists created?

# Common Functionality for all Resources #

Cheffish reuses the common functionality of Chef Resources.

## Actions ##

* `:nothing` Same as the Chef Resource action.

## Attributes ##

The following Attributes are the same as the Chef Resource attributes, with the same defaults.

* `ignore_failure` Same as the Chef Resource Attribute.
* `retries` Same as the Chef Resource Attribute.
* `retry_delay` Same as the Chef Resource Attribute.
* `supports`
* `provider`
* `label` This is a new Attribute that may be used to identify a particular Cheffish resource.

## Guards ##

Just like Chef Resources, the following guards manage the execution of the Cheffish Resource based on the Ruby or shell results. Ruby calls may be used to query the Chef server or make external API calls to a service registry.

### Guard Attributes ###

* `not_if`
* `only_if`

### Guard Arguments ###

* `:user`
* `:group`
* `:environment`
* `:cwd`
* `:timeout`

## Lazy Attribute Evaluation ##

The same as the Chef Resource lazy attribute evaluation.

## Notifications ##

Same behavior as notifications between Chef Resources.

* `notifies`
* `subscribes`

### Notification Timers ###

Same as the notification timers with Chef Resources.

* `:delayed`
* `:immediately`

# Resources #

## Cookbooks ##

### Actions ###

* `:create`
* `:bulk_delete`
* `:download`
* `:upload`
* `site download`
* `site install`

### Attributes ###

* ``

### Providers ###

* ``

### Syntax ###

* ``

### Examples ###

## Environments ##

### Actions ###

* ``

### Attributes ###

* ``

### Providers ###

* ``

### Syntax ###

* ``

### Examples ###

## Roles ##

### Actions ###

* ``

### Attributes ###

* ``

### Providers ###

* ``

### Syntax ###

* ``

### Examples ###

## Data Bags ##

### Actions ###

* ``

### Attributes ###

* ``

### Providers ###

* ``

### Syntax ###

* ``

### Examples ###

## Clients ##

### Actions ###

* `:create`
* `:bootstrap`
* `:run_list_add`
* `:run_list_set`
* `:run_list_delete`
* `:converge`
* `:delete`
* `:apply`
* ``

### Attributes ###

* ``

### Providers ###

* ``

### Syntax ###

* ``

### Examples ###

## Nodes #

### Actions ###

* `:bulk_delete`
* `:create`
* `:delete`
* `:from_file`
* `:run_list_add`
* `:run_list_delete`
* `:run_list_set`

### Attributes ###

* ``

### Providers ###

* ``

### Syntax ###

* ``

### Examples ###


## Instance Providers #

Instance Providers are the actual machines backing the nodes that are created. These may be physical or virtual machines, containers or any other resource that may be represented by a size, type and count.

### Actions ###

* `:bootstrap`
* `:bulk_delete`
* `:converge`
* `:create`
* `:delete`
* `:delete`
* `:from_file`
* `:purge`
* `:run_list_add`
* `:run_list_delete`
* `:run_list_set`

### Attributes ###

* `label` attribute is the name attribute for Instance providers. This may be used to identify a particular Cheffish resource.
* `count` number of instances for a particular provider with this label
* `resize` whether to resize the cluster if the count is different. Default to `false`.

### Providers ###

More specific instance providers. EC2, OpenStack, Rackspace, Docker, LXC, etc.

### Syntax ###

* ``

### Examples ###

## Attributes ##

## SSH ##

### Actions ###

* ``

### Attributes ###

* ``

### Providers ###

* ``

### Syntax ###

* ``

### Examples ###

## Push Jobs #

    quorum
    presence
    heartbeat
    timeout

### Actions ###

* ``

### Attributes ###

* ``

### Providers ###

* ``

### Syntax ###

* ``

### Examples ###

# Open Questions #
Is knife.rb the right file for config?
How do we store/access per-node settings? cheffish['foo.bar.com']['password']?
How do we ensure subscribes/notifies behave idempotently when we make changes to a node? Specify the action?
Organizations and APIs?
Service registry.
Berkshelf support.
don't overload the terminology further. "Instance Providers" used instead of  Resources vs. resources, Provider vs. providers
>>>>>>> Stashed changes
