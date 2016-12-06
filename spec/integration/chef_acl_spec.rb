require "support/spec_support"
require "cheffish/rspec/chef_run_support"
require "chef_zero/version"
require "uri"

if Gem::Version.new(ChefZero::VERSION) >= Gem::Version.new("3.1")
  describe Chef::Resource::ChefAcl do
    extend Cheffish::RSpec::ChefRunSupport

    #        let(:chef_config) { super().merge(log_level: :debug, stdout: STDOUT, stderr: STDERR, log_location: STDOUT) }

    context "Rights attributes" do
      when_the_chef_server "has a node named x", :osc_compat => false do
        node "x", {}

        it 'Converging chef_acl "nodes/x" changes nothing' do
          expect_recipe do
            chef_acl "nodes/x"
          end.to be_up_to_date
          expect(get("nodes/x/_acl")).to partially_match({})
        end

        it 'Converging chef_acl "nodes/x" with "complete true" and no rights raises an error' do
          expect_converge do
            chef_acl "nodes/x" do
              complete true
            end
          end.to raise_error(RuntimeError)
        end

        it "Removing all :grant rights from a node raises an error" do
          expect_converge do
            chef_acl "nodes/x" do
              remove_rights :grant, users: %w{pivotal}, groups: %w{admins users clients}
            end
          end.to raise_error(RuntimeError)
        end

        context 'and a user "blarghle"' do
          user "blarghle", {}

          it 'Converging chef_acl "nodes/x" with user "blarghle" adds the user' do
            expect_recipe do
              chef_acl "nodes/x" do
                rights :read, users: %w{blarghle}
              end
            end.to be_updated
            expect(get("nodes/x/_acl")).to partially_match("read" => { "actors" => %w{blarghle} })
          end

          it 'Converging chef_acl "nodes/x" with "complete true" removes all ACLs except those specified' do
            expect_recipe do
              chef_acl "nodes/x" do
                rights :grant, users: %w{blarghle}
                complete true
              end
            end.to be_updated
            expect(get("nodes/x/_acl")).to eq(
              "create" => { "actors" => [], "groups" => [] },
              "read" => { "actors" => [], "groups" => [] },
              "update" => { "actors" => [], "groups" => [] },
              "delete" => { "actors" => [], "groups" => [] },
              "grant" => { "actors" => ["blarghle"], "groups" => [] }
            )
          end
        end

        it 'Converging chef_acl "nodes/x" with "complete true" removes all ACLs except those specified in :all' do
          expect_recipe do
            chef_acl "nodes/x" do
              rights :all, users: %w{blarghle}
              complete true
            end
          end.to be_updated
          expect(get("nodes/x/_acl")).to eq(
            "create" => { "actors" => ["blarghle"], "groups" => [] },
            "read" => { "actors" => ["blarghle"], "groups" => [] },
            "update" => { "actors" => ["blarghle"], "groups" => [] },
            "delete" => { "actors" => ["blarghle"], "groups" => [] },
            "grant" => { "actors" => ["blarghle"], "groups" => [] }
          )
        end

        context 'and a client "blarghle"' do
          user "blarghle", {}

          it 'Converging chef_acl "nodes/x" with client "blarghle" adds the client' do
            expect_recipe do
              chef_acl "nodes/x" do
                rights :read, clients: %w{blarghle}
              end
            end.to be_updated
            expect(get("nodes/x/_acl")).to partially_match("read" => { "actors" => %w{blarghle} })
          end
        end

        context 'and a group "blarghle"' do
          group "blarghle", {}

          it 'Converging chef_acl "nodes/x" with group "blarghle" adds the group' do
            expect_recipe do
              chef_acl "nodes/x" do
                rights :read, groups: %w{blarghle}
              end
            end.to be_updated
            expect(get("nodes/x/_acl")).to partially_match("read" => { "groups" => %w{blarghle} })
          end
        end

        context "and multiple users and groups" do
          user "u1", {}
          user "u2", {}
          user "u3", {}
          client "c1", {}
          client "c2", {}
          client "c3", {}
          group "g1", {}
          group "g2", {}
          group "g3", {}

          it "Converging chef_acls should ignore order of the values in the acls" do
            expect_recipe do
              chef_acl "nodes/x" do
                rights :create, users:  %w{u1 u2 u3}, clients:  %w{c1 c2 c3}, groups:  %w{g1 g2 g3}
              end
            end.to be_updated
            expect_recipe do
              chef_acl "nodes/x" do
                rights :create, users:  %w{u2 u3 u1}, clients:  %w{c3 c2 c1}, groups:  %w{g1 g2 g3}
              end
            end.to be_up_to_date
          end

          it 'Converging chef_acl "nodes/x" with multiple groups, users and clients in an acl makes the appropriate changes' do
            expect_recipe do
              chef_acl "nodes/x" do
                rights :create, users:  %w{u1 u2 u3}, clients:  %w{c1 c2 c3}, groups:  %w{g1 g2 g3}
              end
            end.to be_updated
            expect(get("nodes/x/_acl")).to partially_match(
              "create" => { "groups" => %w{g1 g2 g3}, "actors" => %w{u1 u2 u3 c1 c2 c3} }
            )
          end

          it 'Converging chef_acl "nodes/x" with multiple groups, users and clients across multiple "rights" groups makes the appropriate changes' do
            expect_recipe do
              chef_acl "nodes/x" do
                rights :create, users:  %w{u1}, clients: %w{c1}, groups: %w{g1}
                rights :create, users:  %w{u2 u3}, clients: %w{c2 c3}, groups: %w{g2}
                rights :read, users: %w{u1}
                rights :read, groups: %w{g1}
              end
            end.to be_updated
            expect(get("nodes/x/_acl")).to partially_match(
              "create" => { "groups" => %w{g1 g2}, "actors" => %w{u1 u2 u3 c1 c2 c3} },
              "read" => { "groups" => %w{g1}, "actors" => %w{u1} }
            )
          end

          it 'Converging chef_acl "nodes/x" with rights [ :read, :create, :update, :delete, :grant ] modifies all rights' do
            expect_recipe do
              chef_acl "nodes/x" do
                rights [ :create, :read, :update, :delete, :grant ], users: %w{u1 u2}, clients: %w{c1}, groups: %w{g1}
              end
            end.to be_updated
            expect(get("nodes/x/_acl")).to partially_match(
              "create" => { "groups" => %w{g1}, "actors" => %w{u1 u2 c1} },
              "read" => { "groups" => %w{g1}, "actors" => %w{u1 u2 c1} },
              "update" => { "groups" => %w{g1}, "actors" => %w{u1 u2 c1} },
              "delete" => { "groups" => %w{g1}, "actors" => %w{u1 u2 c1} },
              "grant" => { "groups" => %w{g1}, "actors" => %w{u1 u2 c1} }
            )
          end

          it 'Converging chef_acl "nodes/x" with rights :all modifies all rights' do
            expect_recipe do
              chef_acl "nodes/x" do
                rights :all, users: %w{u1 u2}, clients: %w{c1}, groups: %w{g1}
              end
            end.to be_updated
            expect(get("nodes/x/_acl")).to partially_match(
              "create" => { "groups" => %w{g1}, "actors" => %w{u1 u2 c1} },
              "read" => { "groups" => %w{g1}, "actors" => %w{u1 u2 c1} },
              "update" => { "groups" => %w{g1}, "actors" => %w{u1 u2 c1} },
              "delete" => { "groups" => %w{g1}, "actors" => %w{u1 u2 c1} },
              "grant" => { "groups" => %w{g1}, "actors" => %w{u1 u2 c1} }
            )
          end
        end

        it 'Converging chef_acl "nodes/y" throws a 404' do
          expect_converge do
            chef_acl "nodes/y"
          end.to raise_error(Net::HTTPServerException)
        end
      end

      when_the_chef_server "has a node named x with user blarghle in its acl", :osc_compat => false do
        user "blarghle", {}
        node "x", {} do
          acl "read" => { "actors" => %w{blarghle} }
        end

        it 'Converging chef_acl "nodes/x" with that user changes nothing' do
          expect_recipe do
            chef_acl "nodes/x" do
              rights :read, users: %w{blarghle}
            end
          end.to be_up_to_date
          expect(get("nodes/x/_acl")).to partially_match({})
        end
      end

      when_the_chef_server "has a node named x with users foo and bar in all its acls", :osc_compat => false do
        user "foo", {}
        user "bar", {}
        node "x", {} do
          acl "create" => { "actors" => %w{foo bar} },
              "read" => { "actors" => %w{foo bar} },
              "update" => { "actors" => %w{foo bar} },
              "delete" => { "actors" => %w{foo bar} },
              "grant" => { "actors" => %w{foo bar} }
        end

        it 'Converging chef_acl "nodes/x" with remove_rights :all removes foo from everything' do
          expect_recipe do
            chef_acl "nodes/x" do
              remove_rights :all, users: %w{foo}
            end
          end.to be_updated
          expect(get("nodes/x/_acl")).to partially_match(
                           "create" => { "actors" => exclude("foo") },
                           "read"   => { "actors" => exclude("foo") },
                           "update" => { "actors" => exclude("foo") },
                           "delete" => { "actors" => exclude("foo") },
                           "grant"  => { "actors" => exclude("foo") }
          )
        end
      end

      ::RSpec::Matchers.define_negated_matcher :exclude, :include

      context "recursive" do
        when_the_chef_server "has a nodes container with user blarghle in its acl", :osc_compat => false do
          user "blarghle", {}
          acl_for "containers/nodes", "read" => { "actors" => %w{blarghle} }
          node "x", {} do
            acl "read" => { "actors" => [] }
          end

          it 'Converging chef_acl "nodes" makes no changes' do
            expect do
              expect_recipe do
                chef_acl "nodes" do
                  rights :read, users: %w{blarghle}
                end
              end.to be_up_to_date
            end.to not_change { get("containers/nodes/_acl") }.
               and not_change { get("nodes/x/_acl") }
          end

          RSpec::Matchers.define_negated_matcher :not_change, :change

          it 'Converging chef_acl "nodes" with recursive :on_change makes no changes' do
            expect do
              expect_recipe do
                chef_acl "nodes" do
                  rights :read, users: %w{blarghle}
                  recursive :on_change
                end
              end.to be_up_to_date
            end.to not_change { get("containers/nodes/_acl") }.
               and not_change { get("nodes/x/_acl") }
          end

          it 'Converging chef_acl "nodes" with recursive true changes nodes/x\'s acls' do
            expect_recipe do
              chef_acl "nodes" do
                rights :read, users: %w{blarghle}
                recursive true
              end
            end.to be_updated
            expect(get("nodes/x/_acl")).to partially_match("read" => { "actors" => %w{blarghle} })
          end

          it 'Converging chef_acl "" with recursive false does not change nodes/x\'s acls' do
            expect_recipe do
              chef_acl "" do
                rights :read, users: %w{blarghle}
                recursive false
              end
            end.to be_updated
            expect(get("containers/nodes/_acl")).to partially_match({})
            expect(get("nodes/x/_acl")).to partially_match({})
          end

          it 'Converging chef_acl "" with recursive :on_change does not change nodes/x\'s acls' do
            expect_recipe do
              chef_acl "" do
                rights :read, users: %w{blarghle}
                recursive :on_change
              end
            end.to be_updated
            expect(get("containers/nodes/_acl")).to partially_match({})
            expect(get("nodes/x/_acl")).to partially_match({})
          end

          it 'Converging chef_acl "" with recursive true changes nodes/x\'s acls' do
            expect_recipe do
              chef_acl "" do
                rights :read, users: %w{blarghle}
                recursive true
              end
            end.to be_updated
            expect(get("/organizations/_acl")).to partially_match("read" => { "actors" => %w{blarghle} })
            expect(get("nodes/x/_acl")).to partially_match("read" => { "actors" => %w{blarghle} })
          end
        end
      end
    end

    context "ACLs on each type of thing" do
      when_the_chef_server "has an organization named foo", :osc_compat => false, :single_org => false do
        organization "foo" do
          user "u", {}
          client "x", {}
          container "x", {}
          cookbook "x", "1.0.0", {}
          data_bag "x", { "y" => {} }
          environment "x", {}
          group "x", {}
          node "x", {}
          role "x", {}
          sandbox "x", {}
          user "x", {}
        end

        organization "bar" do
          user "u", {}
          node "x", {}
        end

        context "and the chef server URL points at /organizations/foo" do
          before :each do
            Chef::Config.chef_server_url = URI.join(Chef::Config.chef_server_url, "/organizations/foo").to_s
          end

          context "relative paths" do
            it "chef_acl 'nodes/x' changes the acls" do
              expect_recipe do
                chef_acl "nodes/x" do
                  rights :read, users: %w{u}
                end
              end.to be_updated
              expect(get("nodes/x/_acl")).to partially_match("read" => { "actors" => %w{u} })
            end

            it "chef_acl '*/*' changes the acls" do
              expect_recipe do
                chef_acl "*/*" do
                  rights :read, users: %w{u}
                end
              end.to be_updated
              %w{clients containers cookbooks data environments groups nodes roles}.each do |type|
                expect(get("/organizations/foo/#{type}/x/_acl")).to partially_match(
                                 "read" => { "actors" => %w{u} })
              end
            end
          end

          context "absolute paths" do
            %w{clients containers cookbooks data environments groups nodes roles sandboxes}.each do |type|
              it "chef_acl '/organizations/foo/#{type}/x' changes the acl" do
                expect_recipe do
                  chef_acl "/organizations/foo/#{type}/x" do
                    rights :read, users: %w{u}
                  end
                end.to be_updated
                expect(get("/organizations/foo/#{type}/x/_acl")).to partially_match("read" => { "actors" => %w{u} })
              end
            end

            %w{clients containers cookbooks data environments groups nodes roles sandboxes}.each do |type|
              it "chef_acl '/organizations/foo/#{type}/x' changes the acl" do
                expect_recipe do
                  chef_acl "/organizations/foo/#{type}/x" do
                    rights :read, users: %w{u}
                  end
                end.to be_updated
                expect(get("/organizations/foo/#{type}/x/_acl")).to partially_match("read" => { "actors" => %w{u} })
              end
            end

            %w{clients containers cookbooks data environments groups nodes roles}.each do |type|
              it "chef_acl '/*/*/#{type}/*' changes the acl" do
                expect_recipe do
                  chef_acl "/*/*/#{type}/*" do
                    rights :read, users: %w{u}
                  end
                end.to be_updated
                expect(get("/organizations/foo/#{type}/x/_acl")).to partially_match("read" => { "actors" => %w{u} })
              end
            end

            it "chef_acl '/*/*/*/x' changes the acls" do
              expect_recipe do
                chef_acl "/*/*/*/x" do
                  rights :read, users: %w{u}
                end
              end.to be_updated
              %w{clients containers cookbooks data environments groups nodes roles sandboxes}.each do |type|
                expect(get("/organizations/foo/#{type}/x/_acl")).to partially_match(
                                 "read" => { "actors" => %w{u} })
              end
            end

            it "chef_acl '/*/*/*/*' changes the acls" do
              expect_recipe do
                chef_acl "/*/*/*/*" do
                  rights :read, users: %w{u}
                end
              end.to be_updated
              %w{clients containers cookbooks data environments groups nodes roles}.each do |type|
                expect(get("/organizations/foo/#{type}/x/_acl")).to partially_match(
                                 "read" => { "actors" => %w{u} })
              end
            end

            it 'chef_acl "/organizations/foo/data_bags/x" changes the acl' do
              expect_recipe do
                chef_acl "/organizations/foo/data_bags/x" do
                  rights :read, users: %w{u}
                end
              end.to be_updated
              expect(get("/organizations/foo/data/x/_acl")).to partially_match("read" => { "actors" => %w{u} })
            end

            it 'chef_acl "/*/*/data_bags/*" changes the acl' do
              expect_recipe do
                chef_acl "/*/*/data_bags/*" do
                  rights :read, users: %w{u}
                end
              end.to be_updated
              expect(get("/organizations/foo/data/x/_acl")).to partially_match("read" => { "actors" => %w{u} })
            end

            it "chef_acl '/organizations/foo/cookbooks/x/1.0.0' raises an error" do
              expect_converge do
                chef_acl "/organizations/foo/cookbooks/x/1.0.0" do
                  rights :read, users: %w{u}
                end
              end.to raise_error(/ACLs cannot be set on children of \/organizations\/foo\/cookbooks\/x/)
            end

            it "chef_acl '/organizations/foo/cookbooks/*/*' raises an error" do
              pending
              expect_converge do
                chef_acl "/organizations/foo/cookbooks/*/*" do
                  rights :read, users: %w{u}
                end
              end.to raise_error(/ACLs cannot be set on children of \/organizations\/foo\/cookbooks\/*/)
            end

            it 'chef_acl "/organizations/foo/data/x/y" raises an error' do
              expect_converge do
                chef_acl "/organizations/foo/data/x/y" do
                  rights :read, users: %w{u}
                end
              end.to raise_error(/ACLs cannot be set on children of \/organizations\/foo\/data\/x/)
            end

            it 'chef_acl "/organizations/foo/data/*/*" raises an error' do
              pending
              expect_converge do
                chef_acl "/organizations/foo/data/*/*" do
                  rights :read, users: %w{u}
                end
              end.to raise_error(/ACLs cannot be set on children of \/organizations\/foo\/data\/*/)
            end

            it 'chef_acl "/organizations/foo" changes the acl' do
              expect_recipe do
                chef_acl "/organizations/foo" do
                  rights :read, users: %w{u}
                end
              end.to be_updated
              expect(get("/organizations/foo/organizations/_acl")).to partially_match("read" => { "actors" => %w{u} })
              expect(get("/organizations/foo/nodes/x/_acl")).to partially_match("read" => { "actors" => %w{u} })
            end

            it 'chef_acl "/organizations/*" changes the acl' do
              expect_recipe do
                chef_acl "/organizations/*" do
                  rights :read, users: %w{u}
                end
              end.to be_updated
              expect(get("/organizations/foo/organizations/_acl")).to partially_match("read" => { "actors" => %w{u} })
              expect(get("/organizations/foo/nodes/x/_acl")).to partially_match("read" => { "actors" => %w{u} })
            end

            it 'chef_acl "/users/x" changes the acl' do
              expect_recipe do
                chef_acl "/users/x" do
                  rights :read, users: %w{u}
                end
              end.to be_updated
              expect(get("/users/x/_acl")).to partially_match("read" => { "actors" => %w{u} })
            end

            it 'chef_acl "/users/*" changes the acl' do
              expect_recipe do
                chef_acl "/users/*" do
                  rights :read, users: %w{u}
                end
              end.to be_updated
              expect(get("/users/x/_acl")).to partially_match("read" => { "actors" => %w{u} })
            end

            it 'chef_acl "/*/x" changes the acl' do
              expect_recipe do
                chef_acl "/*/x" do
                  rights :read, users: %w{u}
                end
              end.to be_updated
              expect(get("/users/x/_acl")).to partially_match("read" => { "actors" => %w{u} })
            end

            it 'chef_acl "/*/*" changes the acl' do
              expect_recipe do
                chef_acl "/*/*" do
                  rights :read, users: %w{u}
                end
              end.to be_updated
              expect(get("/organizations/foo/organizations/_acl")).to partially_match("read" => { "actors" => %w{u} })
              expect(get("/users/x/_acl")).to partially_match("read" => { "actors" => %w{u} })
            end
          end
        end

        context "and the chef server URL points at /organizations/bar" do
          before :each do
            Chef::Config.chef_server_url = URI.join(Chef::Config.chef_server_url.to_s, "/organizations/bar").to_s
          end

          it "chef_acl '/organizations/foo/nodes/*' changes the acl" do
            expect_recipe do
              chef_acl "/organizations/foo/nodes/*" do
                rights :read, users: %w{u}
              end
            end.to be_updated
            expect(get("/organizations/foo/nodes/x/_acl")).to partially_match("read" => { "actors" => %w{u} })
          end
        end

        context "and the chef server URL points at /" do
          before :each do
            Chef::Config.chef_server_url = URI.join(Chef::Config.chef_server_url.to_s, "/").to_s
          end

          it "chef_acl '/organizations/foo/nodes/*' changes the acl" do
            expect_recipe do
              chef_acl "/organizations/foo/nodes/*" do
                rights :read, users: %w{u}
              end
            end.to be_updated
            expect(get("/organizations/foo/nodes/x/_acl")).to partially_match("read" => { "actors" => %w{u} })
          end
        end
      end

      when_the_chef_server 'has a user "u" in single org mode', :osc_compat => false do
        user "u", {}
        client "x", {}
        container "x", {}
        cookbook "x", "1.0.0", {}
        data_bag "x", { "y" => {} }
        environment "x", {}
        group "x", {}
        node "x", {}
        role "x", {}
        sandbox "x", {}
        user "x", {}

        %w{clients containers cookbooks data environments groups nodes roles sandboxes}.each do |type|
          it "chef_acl #{type}/x' changes the acl" do
            expect_recipe do
              chef_acl "#{type}/x" do
                rights :read, users: %w{u}
              end
            end.to be_updated
            expect(get("#{type}/x/_acl")).to partially_match("read" => { "actors" => %w{u} })
          end
        end

        %w{clients containers cookbooks data environments groups nodes roles}.each do |type|
          it "chef_acl '#{type}/*' changes the acl" do
            expect_recipe do
              chef_acl "#{type}/*" do
                rights :read, users: %w{u}
              end
            end.to be_updated
            expect(get("#{type}/x/_acl")).to partially_match("read" => { "actors" => %w{u} })
          end
        end

        it "chef_acl '*/x' changes the acls" do
          expect_recipe do
            chef_acl "*/x" do
              rights :read, users: %w{u}
            end
          end.to be_updated
          %w{clients containers cookbooks data environments groups nodes roles sandboxes}.each do |type|
            expect(get("#{type}/x/_acl")).to partially_match(
                             "read" => { "actors" => %w{u} })
          end
        end

        it "chef_acl '*/*' changes the acls" do
          expect_recipe do
            chef_acl "*/*" do
              rights :read, users: %w{u}
            end
          end.to be_updated
          %w{clients containers cookbooks data environments groups nodes roles}.each do |type|
            expect(get("#{type}/x/_acl")).to partially_match(
                             "read" => { "actors" => %w{u} })
          end
        end

        it "chef_acl 'groups/*' changes the acl" do
          expect_recipe do
            chef_acl "groups/*" do
              rights :read, users: %w{u}
            end
          end.to be_updated
          %w{admins billing-admins clients users x}.each do |n|
            expect(get("groups/#{n}/_acl")).to partially_match(
                             "read" => { "actors" => %w{u} })
          end
        end

        it 'chef_acl "data_bags/x" changes the acl' do
          expect_recipe do
            chef_acl "data_bags/x" do
              rights :read, users: %w{u}
            end
          end.to be_updated
          expect(get("data/x/_acl")).to partially_match("read" => { "actors" => %w{u} })
        end

        it 'chef_acl "data_bags/*" changes the acl' do
          expect_recipe do
            chef_acl "data_bags/*" do
              rights :read, users: %w{u}
            end
          end.to be_updated
          expect(get("data/x/_acl")).to partially_match("read" => { "actors" => %w{u} })
        end

        it 'chef_acl "" changes the organization acl' do
          expect_recipe do
            chef_acl "" do
              rights :read, users: %w{u}
            end
          end.to be_updated
          expect(get("/organizations/_acl")).to partially_match("read" => { "actors" => %w{u} })
          expect(get("nodes/x/_acl")).to partially_match("read" => { "actors" => %w{u} })
        end
      end
    end

    context "ACLs on each container type" do
      when_the_chef_server "has an organization named foo", :osc_compat => false, :single_org => false do
        organization "foo" do
          user "u", {}
          client "x", {}
          container "x", {}
          cookbook "x", "1.0.0", {}
          data_bag "x", { "y" => {} }
          environment "x", {}
          group "x", {}
          node "x", {}
          role "x", {}
          sandbox "x", {}
          user "x", {}
        end

        %w{clients containers cookbooks data environments groups nodes roles sandboxes}.each do |type|
          it "chef_acl '/organizations/foo/#{type}' changes the acl" do
            expect_recipe do
              chef_acl "/organizations/foo/#{type}" do
                rights :read, users: %w{u}
              end
            end.to be_updated
            expect(get("/organizations/foo/containers/#{type}/_acl")).to partially_match("read" => { "actors" => %w{u} })
          end
        end

        %w{clients containers cookbooks data environments groups nodes roles}.each do |type|
          it "chef_acl '/*/*/#{type}' changes the acl" do
            expect_recipe do
              chef_acl "/*/*/#{type}" do
                rights :read, users: %w{u}
              end
            end.to be_updated
            expect(get("/organizations/foo/containers/#{type}/_acl")).to partially_match("read" => { "actors" => %w{u} })
          end
        end

        it "chef_acl '/*/*/*' changes the acls" do
          expect_recipe do
            chef_acl "/*/*/*" do
              rights :read, users: %w{u}
            end
          end.to be_updated
          %w{clients containers cookbooks data environments groups nodes roles sandboxes}.each do |type|
            expect(get("/organizations/foo/containers/#{type}/_acl")).to partially_match(
                             "read" => { "actors" => %w{u} })
          end
        end

        it 'chef_acl "/organizations/foo/data_bags" changes the acl' do
          expect_recipe do
            chef_acl "/organizations/foo/data_bags" do
              rights :read, users: %w{u}
            end
          end.to be_updated
          expect(get("/organizations/foo/containers/data/_acl")).to partially_match("read" => { "actors" => %w{u} })
        end

        it 'chef_acl "/*/*/data_bags" changes the acl' do
          expect_recipe do
            chef_acl "/*/*/data_bags" do
              rights :read, users: %w{u}
            end
          end.to be_updated
          expect(get("/organizations/foo/containers/data/_acl")).to partially_match("read" => { "actors" => %w{u} })
        end
      end

      when_the_chef_server 'has a user "u" in single org mode', :osc_compat => false do
        user "u", {}
        client "x", {}
        container "x", {}
        cookbook "x", "1.0.0", {}
        data_bag "x", { "y" => {} }
        environment "x", {}
        group "x", {}
        node "x", {}
        role "x", {}
        sandbox "x", {}
        user "x", {}

        %w{clients containers cookbooks data environments groups nodes roles sandboxes}.each do |type|
          it "chef_acl #{type}' changes the acl" do
            expect_recipe do
              chef_acl "#{type}" do
                rights :read, users: %w{u}
              end
            end.to be_updated
            expect(get("containers/#{type}/_acl")).to partially_match("read" => { "actors" => %w{u} })
          end
        end

        it "chef_acl '*' changes the acls" do
          expect_recipe do
            chef_acl "*" do
              rights :read, users: %w{u}
            end
          end.to be_updated
          %w{clients containers cookbooks data environments groups nodes roles sandboxes}.each do |type|
            expect(get("containers/#{type}/_acl")).to partially_match(
                             "read" => { "actors" => %w{u} })
          end
        end
      end
    end

    context "remove_rights" do
      when_the_chef_server 'has a node "x" with "u", "c" and "g" in its acl', :osc_compat => false do
        user "u", {}
        user "u2", {}
        client "c", {}
        client "c2", {}
        group "g", {}
        group "g2", {}
        node "x", {} do
          acl "create" => { "actors" => %w{u c}, "groups" => [ "g" ] },
              "read"   => { "actors" => %w{u c}, "groups" => [ "g" ] },
              "update" => { "actors" => %w{u c}, "groups" => [ "g" ] }
        end

        it 'chef_acl with remove_rights "u" removes the user\'s rights' do
          expect_recipe do
            chef_acl "nodes/x" do
              remove_rights :read, users: %w{u}
            end
          end.to be_updated
          expect(get("nodes/x/_acl")).to partially_match("read" => { "actors" => exclude("u") })
        end

        it 'chef_acl with remove_rights "c" removes the client\'s rights' do
          expect_recipe do
            chef_acl "nodes/x" do
              remove_rights :read, clients: %w{c}
            end
          end.to be_updated
          expect(get("nodes/x/_acl")).to partially_match("read" => { "actors" => exclude("c") })
        end

        it 'chef_acl with remove_rights "g" removes the group\'s rights' do
          expect_recipe do
            chef_acl "nodes/x" do
              remove_rights :read, groups: %w{g}
            end
          end.to be_updated
          expect(get("nodes/x/_acl")).to partially_match(
            "read" => { "groups" => exclude("g") }
          )
        end

        it 'chef_acl with remove_rights [ :create, :read ], "u", "c", "g" removes all three' do
          expect_recipe do
            chef_acl "nodes/x" do
              remove_rights [ :create, :read ], users: %w{u}, clients: %w{c}, groups: %w{g}
            end
          end.to be_updated
          expect(get("nodes/x/_acl")).to partially_match(
            "create" => { "actors" => exclude("u").and(exclude("c")), "groups" => exclude("g") },
            "read"   => { "actors" => exclude("u").and(exclude("c")), "groups" => exclude("g") }
          )
        end

        it 'chef_acl with remove_rights "u2", "c2", "g2" has no effect' do
          expect do
            expect_recipe do
              chef_acl "nodes/x" do
                remove_rights :read, users: %w{u2}, clients: %w{c2}, groups: %w{g2}
              end
            end.to be_up_to_date
          end.not_to change { get("nodes/x/_acl") }
        end
      end
    end

    when_the_chef_server "has a node named data_bags", :osc_compat => false do
      user "blarghle", {}
      node "data_bags", {}

      it 'Converging chef_acl "nodes/data_bags" with user "blarghle" adds the user' do
        expect_recipe do
          chef_acl "nodes/data_bags" do
            rights :read, users: %w{blarghle}
          end
        end.to be_updated
        expect(get("nodes/data_bags/_acl")).to partially_match("read" => { "actors" => %w{blarghle} })
      end
    end

    when_the_chef_server "has a node named data_bags in multi-org mode", :osc_compat => false, :single_org => false do
      user "blarghle", {}
      organization "foo" do
        node "data_bags", {}
      end

      it 'Converging chef_acl "/organizations/foo/nodes/data_bags" with user "blarghle" adds the user' do
        expect_recipe do
          chef_acl "/organizations/foo/nodes/data_bags" do
            rights :read, users: %w{blarghle}
          end
        end.to be_updated
        expect(get("/organizations/foo/nodes/data_bags/_acl")).to partially_match("read" => { "actors" => %w{blarghle} })
      end
    end

    when_the_chef_server "has a user named data_bags in multi-org mode", :osc_compat => false, :single_org => false do
      user "data_bags", {}
      user "blarghle", {}

      it 'Converging chef_acl "/users/data_bags" with user "blarghle" adds the user' do
        expect_recipe do
          chef_acl "/users/data_bags" do
            rights :read, users: %w{blarghle}
          end
        end.to be_updated
        expect(get("/users/data_bags/_acl")).to partially_match("read" => { "actors" => %w{blarghle} })
      end
    end
  end
end
