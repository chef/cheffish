# Change Log

## [v1.4.0](https://github.com/chef/cheffish/tree/HEAD)

[Full Changelog](https://github.com/chef/cheffish/compare/v1.3.1...v1.4.0)

**Implemented enhancements:**

- cdoherty's travis matrix with 12.3.0 fixes [\#64](https://github.com/chef/cheffish/pull/64) ([jkeiser](https://github.com/jkeiser))
- Add provides statements to avoid chef-client warnings [\#60](https://github.com/chef/cheffish/pull/60) ([stevendanna](https://github.com/stevendanna))

**Fixed bugs:**

- chef\_server\_api does not correctly handle MergedConfig [\#65](https://github.com/chef/cheffish/issues/65)
- Modified Resources and Providers creation [\#70](https://github.com/chef/cheffish/pull/70) ([afiune](https://github.com/afiune))
- A handful of fixes to make the Cheffish matrix pass on all the relevant Chef versions. [\#68](https://github.com/chef/cheffish/pull/68) ([randomcamel](https://github.com/randomcamel))
- Fix sense typos in test names. [\#59](https://github.com/chef/cheffish/pull/59) ([randomcamel](https://github.com/randomcamel))
- Use correct user-association endpoint for Chef 12 [\#50](https://github.com/chef/cheffish/pull/50) ([stevendanna](https://github.com/stevendanna))

**Closed issues:**

- ffi-yajl version incompatibility with Chef 12.1.2 [\#67](https://github.com/chef/cheffish/issues/67)

## [v1.3.1](https://github.com/chef/cheffish/tree/v1.3.1) (2015-08-05)
[Full Changelog](https://github.com/chef/cheffish/compare/v1.3.0...v1.3.1)

**Fixed bugs:**

- Idempotency of machine resource is broken due to v1 vs v0 differences in clients API [\#56](https://github.com/chef/cheffish/issues/56)
- Pin chef server api version to 0, fixes \#56 [\#57](https://github.com/chef/cheffish/pull/57) ([sersut](https://github.com/sersut))

## [v1.3.0](https://github.com/chef/cheffish/tree/v1.3.0) (2015-07-29)
[Full Changelog](https://github.com/chef/cheffish/compare/v1.2.1...v1.3.0)

## [v1.2.1](https://github.com/chef/cheffish/tree/v1.2.1) (2015-07-17)
[Full Changelog](https://github.com/chef/cheffish/compare/v1.2...v1.2.1)

**Closed issues:**

- There is no documentation / README [\#48](https://github.com/chef/cheffish/issues/48)
- document how to disable ssl verification [\#37](https://github.com/chef/cheffish/issues/37)
- A better Readme [\#30](https://github.com/chef/cheffish/issues/30)

**Merged pull requests:**

- avoid nilerror [\#55](https://github.com/chef/cheffish/pull/55) ([lamont-granquist](https://github.com/lamont-granquist))
- Rewrite README.md [\#51](https://github.com/chef/cheffish/pull/51) ([randomcamel](https://github.com/randomcamel))

## [v1.2](https://github.com/chef/cheffish/tree/v1.2) (2015-05-02)
[Full Changelog](https://github.com/chef/cheffish/compare/v1.1.2...v1.2)

**Merged pull requests:**

- Add .logged\_warnings/errors/info to ChefRun; add emit\_no\_warnings\_or\_err... [\#47](https://github.com/chef/cheffish/pull/47) ([jkeiser](https://github.com/jkeiser))
- Use expect\_recipe universally in Cheffish, use generic rspec matchers instead of update\_acl [\#44](https://github.com/chef/cheffish/pull/44) ([jkeiser](https://github.com/jkeiser))

## [v1.1.2](https://github.com/chef/cheffish/tree/v1.1.2) (2015-04-08)
[Full Changelog](https://github.com/chef/cheffish/compare/v1.1.1...v1.1.2)

**Merged pull requests:**

- Fixing bug @patrick-wright discovered in debug log [\#45](https://github.com/chef/cheffish/pull/45) ([tyler-ball](https://github.com/tyler-ball))

## [v1.1.1](https://github.com/chef/cheffish/tree/v1.1.1) (2015-04-07)
[Full Changelog](https://github.com/chef/cheffish/compare/v1.1.0...v1.1.1)

## [v1.1.0](https://github.com/chef/cheffish/tree/v1.1.0) (2015-04-07)
[Full Changelog](https://github.com/chef/cheffish/compare/v1.0.0...v1.1.0)

**Merged pull requests:**

- Add encapsulated Chef runs that capture and stream output [\#43](https://github.com/chef/cheffish/pull/43) ([jkeiser](https://github.com/jkeiser))

## [v1.0.0](https://github.com/chef/cheffish/tree/v1.0.0) (2015-04-02)
[Full Changelog](https://github.com/chef/cheffish/compare/v1.0.0.rc.1...v1.0.0)

## [v1.0.0.rc.1](https://github.com/chef/cheffish/tree/v1.0.0.rc.1) (2015-04-01)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.10...v1.0.0.rc.1)

## [v0.10](https://github.com/chef/cheffish/tree/v0.10) (2015-03-17)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.9.2...v0.10)

**Fixed bugs:**

- chef\_node creates node resource that cannot update itself [\#2](https://github.com/chef/cheffish/issues/2)

**Closed issues:**

- chef group resource/provider seems broken against chef 12 server [\#38](https://github.com/chef/cheffish/issues/38)

**Merged pull requests:**

- Allow node attributes to be used as input to new\_json / augment\_new\_json \(fixes chef/chef-provisioning\#21\) [\#42](https://github.com/chef/cheffish/pull/42) ([jkeiser](https://github.com/jkeiser))
- Extracting the spec helper to its own class in lib so we can leverage it in chef-provisioning for testing there [\#41](https://github.com/chef/cheffish/pull/41) ([tyler-ball](https://github.com/tyler-ball))
- Update metadata.rb [\#39](https://github.com/chef/cheffish/pull/39) ([oker1](https://github.com/oker1))

## [v0.9.2](https://github.com/chef/cheffish/tree/v0.9.2) (2015-01-27)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.9.1...v0.9.2)

**Merged pull requests:**

- Use appropriate function call for chef 12 [\#33](https://github.com/chef/cheffish/pull/33) ([elliott-davis](https://github.com/elliott-davis))

## [v0.9.1](https://github.com/chef/cheffish/tree/v0.9.1) (2015-01-16)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.9...v0.9.1)

**Fixed bugs:**

- chef\_user resource does not provide display\_name [\#26](https://github.com/chef/cheffish/issues/26)

**Merged pull requests:**

- Fix remove\_role calling self.role instead of referencing block variable. [\#31](https://github.com/chef/cheffish/pull/31) ([causton81](https://github.com/causton81))
- Add user full name to chef\_user [\#27](https://github.com/chef/cheffish/pull/27) ([charlesjohnson](https://github.com/charlesjohnson))
- Fix ChefMirror referencing chef\_server :client\_key [\#23](https://github.com/chef/cheffish/pull/23) ([johnbellone](https://github.com/johnbellone))

## [v0.9](https://github.com/chef/cheffish/tree/v0.9) (2014-11-05)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.8.4...v0.9)

**Merged pull requests:**

- Work with chef12 [\#29](https://github.com/chef/cheffish/pull/29) ([jkeiser](https://github.com/jkeiser))

## [v0.8.4](https://github.com/chef/cheffish/tree/v0.8.4) (2014-11-04)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.8.3...v0.8.4)

## [v0.8.3](https://github.com/chef/cheffish/tree/v0.8.3) (2014-09-26)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.8.2...v0.8.3)

**Closed issues:**

- Multiple cookbook\_path: broken with recent cheffish \(~\> 0.8\)  [\#22](https://github.com/chef/cheffish/issues/22)

**Merged pull requests:**

- Honor settings in recipes [\#25](https://github.com/chef/cheffish/pull/25) ([johnewart](https://github.com/johnewart))

## [v0.8.2](https://github.com/chef/cheffish/tree/v0.8.2) (2014-09-08)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.8.1...v0.8.2)

## [v0.8.1](https://github.com/chef/cheffish/tree/v0.8.1) (2014-09-08)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.8...v0.8.1)

**Merged pull requests:**

- perform a deep merge of the current resource and new resource in new\_json [\#20](https://github.com/chef/cheffish/pull/20) ([mwrock](https://github.com/mwrock))

## [v0.8](https://github.com/chef/cheffish/tree/v0.8) (2014-09-05)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.7.1...v0.8)

**Implemented enhancements:**

- Support groups and acls in all objects that support them [\#12](https://github.com/chef/cheffish/issues/12)

**Fixed bugs:**

- Docs and/or gemspec should specify required Chef version [\#7](https://github.com/chef/cheffish/issues/7)

**Closed issues:**

- Support policies [\#14](https://github.com/chef/cheffish/issues/14)
- Support acls, groups, containers, org membership and invites [\#11](https://github.com/chef/cheffish/issues/11)

**Merged pull requests:**

- Enterprise resources [\#17](https://github.com/chef/cheffish/pull/17) ([jkeiser](https://github.com/jkeiser))
- chef\_acl resource [\#16](https://github.com/chef/cheffish/pull/16) ([jkeiser](https://github.com/jkeiser))
- Fix problem when setting public key from String. [\#15](https://github.com/chef/cheffish/pull/15) ([johnbellone](https://github.com/johnbellone))
- improve debug experience for MergedConfig [\#8](https://github.com/chef/cheffish/pull/8) ([mwrock](https://github.com/mwrock))

## [v0.7.1](https://github.com/chef/cheffish/tree/v0.7.1) (2014-08-19)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.7...v0.7.1)

## [v0.7](https://github.com/chef/cheffish/tree/v0.7) (2014-07-15)
[Full Changelog](https://github.com/chef/cheffish/compare/blah...v0.7)

## [blah](https://github.com/chef/cheffish/tree/blah) (2014-06-20)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.6.2...blah)

**Merged pull requests:**

- fix get\_private\_keys for edge cases [\#6](https://github.com/chef/cheffish/pull/6) ([lamont-granquist](https://github.com/lamont-granquist))

## [v0.6.2](https://github.com/chef/cheffish/tree/v0.6.2) (2014-06-18)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.6.1...v0.6.2)

## [v0.6.1](https://github.com/chef/cheffish/tree/v0.6.1) (2014-06-18)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.6...v0.6.1)

## [v0.6](https://github.com/chef/cheffish/tree/v0.6) (2014-06-18)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.5...v0.6)

## [v0.5](https://github.com/chef/cheffish/tree/v0.5) (2014-06-04)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.5.beta.4...v0.5)

## [v0.5.beta.4](https://github.com/chef/cheffish/tree/v0.5.beta.4) (2014-05-31)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.5.beta.3...v0.5.beta.4)

## [v0.5.beta.3](https://github.com/chef/cheffish/tree/v0.5.beta.3) (2014-05-28)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.5.beta.2...v0.5.beta.3)

## [v0.5.beta.2](https://github.com/chef/cheffish/tree/v0.5.beta.2) (2014-05-28)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.5.beta...v0.5.beta.2)

## [v0.5.beta](https://github.com/chef/cheffish/tree/v0.5.beta) (2014-05-23)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.4.1...v0.5.beta)

## [v0.4.1](https://github.com/chef/cheffish/tree/v0.4.1) (2014-05-07)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.4...v0.4.1)

## [v0.4](https://github.com/chef/cheffish/tree/v0.4) (2014-05-01)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.3...v0.4)

**Merged pull requests:**

- Skip 1.8.7 Travis builds since cheffish doesn’t support them. [\#5](https://github.com/chef/cheffish/pull/5) ([andrewdotn](https://github.com/andrewdotn))
- Support PKCS\#8 SHA1 fingerprints used by AWS for generated keys. [\#4](https://github.com/chef/cheffish/pull/4) ([andrewdotn](https://github.com/andrewdotn))

## [v0.3](https://github.com/chef/cheffish/tree/v0.3) (2014-04-24)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.2.2...v0.3)

**Merged pull requests:**

- Dt/local server stop [\#3](https://github.com/chef/cheffish/pull/3) ([doubt72](https://github.com/doubt72))

## [v0.2.2](https://github.com/chef/cheffish/tree/v0.2.2) (2014-04-13)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.2.1...v0.2.2)

## [v0.2.1](https://github.com/chef/cheffish/tree/v0.2.1) (2014-04-11)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.2...v0.2.1)

## [v0.2](https://github.com/chef/cheffish/tree/v0.2) (2014-03-04)
[Full Changelog](https://github.com/chef/cheffish/compare/v0.1...v0.2)

## [v0.1](https://github.com/chef/cheffish/tree/v0.1) (2013-12-12)


\* *This Change Log was automatically generated by [github_changelog_generator](https://github.com/skywinder/Github-Changelog-Generator)*
