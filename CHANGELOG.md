# Changelog

## 0.9.1 (1/15/2014)

- Add Chef 12 display_name support to chef_user (@charlesjohnson)
- Fix chef_mirror when run against real Chef servers (@johnbellone)
- Fix crash in honor_local_mode (@mwrock)
- Fix remove_role to actually remove the role (@causton81)

## 0.9 (11/4/2014)

- Work with Chef 12 as well as 11

## 0.8.4 (11/4/2014)

- Remove Chef as an explicit dependency so it can be included as a plugin

## 0.8.3 (9/26/2014)

- Fix for honoring with_ attributes as symbols or strings

## 0.8.2 (9/8/2014)

- Fix issue with attribute merge

## 0.8.1 (9/8/2014)

- Fix Cheffish against Chef 11 client
- Fix normal attributes that are sometimes overwritten (@mwrock)
- Get chef_mirror.versioned_cookbooks working

## 0.8 (9/5/2014)

- FEATURE: Enterprise and Chef 12 support!
  - chef_acl, chef_group, chef_container resources to manipulate ACLs and groups
  - chef_organization resource to create and delete Chef organizations and add members/invitations
- FEATURE: chef_mirror with :download and :upload support: lets you mirror all or part of a Chef repository and the Chef server.  Uses `ChefFS`, the technology behind `knife upload` and `knife download`, to do the dirty work.
- Fix issue when specifying Private Key as a string (@johnbellone)
- Make MergedConfig more readable (@mwrock)

## 0.7.1 (8/18/2014)

- Fix Cheffish to work with latest Chef

## 0.7 (7/15/2014)

- fix issue with encrypted private keys being overwritten
- fix private key discovery when directories are missing (@lcg)

## 0.6.2 (6/18/2014)

- fix Cheffish.get_private_key when private key does not exist

## 0.6 (6/18/2014)

- remove PKCS8 as a required dependency
- Allow `chef_client.source_key_path` and `chef_user.source_key_path` to specify keys in `Chef::Config.private_key_paths`
- Robustify `private_key` named key handling to deal with multiple key paths so `private_key 'blah'` will Just Work
- Fix bug with direct calls to Cheffish.get_private_key

## 0.5 (6/3/2014)

- Support relative directories and Chef::Config.private_key_paths in private_key resource
- add support for profiled configs with Cheffish::MergedConfig and Cheffish.profiled_config
- work better with multiple threads (store config in instances)
- Add helper methods Cheffish.load_chef_config and Cheffish.honor_local_mode for embedders
- Fix crashes with PKCS8 on Ruby 2.0+

## 0.4.1 (5/7/2014)

- Expose Cheffish.default_chef_server
- Make prettier green text when chef objects update

## 0.4 (5/1/2014)

- Interface: change Cheffish.inline_resource() to take both provider and action
- Interface: Rename enclosing_chef_server, enclosing_* to current_*
- Use Chef client in a more standard and extensible way
- Internal changes to make Cheffish more parallizable (no more globals)

## 0.3 (4/23/2014)

- Preserve tags when attributes hash is set
- Remove ability to specify automatic/default/override attributes (these are for recipes!)
- Preserve automatic/default/override attributes when modifying nodes (don't overwrite what recipes wrote)
- @doubt72 new Cheffish::RecipeDSL.stop_local_servers method to stop all local servers after running a recipe

## 0.2.2 (4/12/2014)

- make sure private keys have the right mode (not group or world-readable)

## 0.2.1 (4/11/2014)

- fix missing require
