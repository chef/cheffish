require "support/spec_support"
require "cheffish/rspec/chef_run_support"

describe Chef::Resource::ChefOrganization do
  extend Cheffish::RSpec::ChefRunSupport

  when_the_chef_12_server "is in multi-org mode" do
    context "and chef_server_url is pointed at the top level" do
      user "u", {}
      user "u2", {}

      it 'chef_organization "x" creates the organization' do
        expect_recipe do
          chef_organization "x"
        end.to have_updated("chef_organization[x]", :create)
        expect(get("/organizations/x")["full_name"]).to eq("x")
      end
    end

    context "and chef_server_url is pointed at /organizations/foo" do
      organization "foo"

      before :each do
        Chef::Config.chef_server_url = URI.join(Chef::Config.chef_server_url, "/organizations/foo").to_s
      end

      context "and is empty" do
        user "u", {}
        user "u2", {}

        it 'chef_organization "x" creates the organization' do
          expect_recipe do
            chef_organization "x"
          end.to have_updated("chef_organization[x]", :create)
          expect(get("/organizations/x")["full_name"]).to eq("x")
        end

        it 'chef_organization "x" with full_name creates the organization' do
          expect_recipe do
            chef_organization "x" do
              full_name "Hi"
            end
          end.to have_updated("chef_organization[x]", :create)
          expect(get("/organizations/x")["full_name"]).to eq("Hi")
        end

        it 'chef_organization "x" and inviting users creates the invites' do
          expect_recipe do
            chef_organization "x" do
              invites "u", "u2"
            end
          end.to have_updated("chef_organization[x]", :create)
          expect(get("/organizations/x/association_requests").map { |u| u["username"] }).to eq(%w{u u2})
        end

        it 'chef_organization "x" adds members' do
          expect_recipe do
            chef_organization "x" do
              members "u", "u2"
            end
          end.to have_updated("chef_organization[x]", :create)
          expect(get("/organizations/x/users").map { |u| u["user"]["username"] }).to eq(%w{u u2})
        end
      end

      context "and already has an organization named x" do
        user "u", {}
        user "u2", {}
        user "u3", {}
        user "member", {}
        user "member2", {}
        user "invited", {}
        user "invited2", {}
        organization "x", { "full_name" => "Lo" } do
          org_member "member", "member2"
          org_invite "invited", "invited2"
        end

        it 'chef_organization "x" changes nothing' do
          expect_recipe do
            chef_organization "x"
          end.not_to have_updated("chef_organization[x]", :create)
          expect(get("/organizations/x")["full_name"]).to eq("Lo")
        end

        it 'chef_organization "x" with "complete true" reverts the full_name' do
          expect_recipe do
            chef_organization "x" do
              complete true
            end
          end.to have_updated("chef_organization[x]", :create)
          expect(get("/organizations/x")["full_name"]).to eq("x")
        end

        it 'chef_organization "x" with new full_name updates the organization' do
          expect_recipe do
            chef_organization "x" do
              full_name "Hi"
            end
          end.to have_updated("chef_organization[x]", :create)
          expect(get("/organizations/x")["full_name"]).to eq("Hi")
        end

        context "invites and membership tests" do
          it 'chef_organization "x" and inviting users creates the invites' do
            expect_recipe do
              chef_organization "x" do
                invites "u", "u2"
              end
            end.to have_updated("chef_organization[x]", :create)
            expect(get("/organizations/x/association_requests").map { |u| u["username"] }).to eq(%w{invited invited2 u u2})
          end

          it 'chef_organization "x" adds members' do
            expect_recipe do
              chef_organization "x" do
                members "u", "u2"
              end
            end.to have_updated("chef_organization[x]", :create)
            expect(get("/organizations/x/users").map { |u| u["user"]["username"] }).to eq(%w{member member2 u u2})
          end

          it 'chef_organization "x" does nothing when inviting already-invited users and members' do
            expect_recipe do
              chef_organization "x" do
                invites "invited", "member"
              end
            end.not_to have_updated("chef_organization[x]", :create)
            expect(get("/organizations/x/association_requests").map { |u| u["username"] }).to eq(%w{invited invited2})
            expect(get("/organizations/x/users").map { |u| u["user"]["username"] }).to eq(%w{member member2})
          end

          it 'chef_organization "x" does nothing when adding members who are already members' do
            expect_recipe do
              chef_organization "x" do
                members "member"
              end
            end.not_to have_updated("chef_organization[x]", :create)
            expect(get("/organizations/x/association_requests").map { |u| u["username"] }).to eq(%w{invited invited2})
            expect(get("/organizations/x/users").map { |u| u["user"]["username"] }).to eq(%w{member member2})
          end

          it 'chef_organization "x" upgrades invites to members when asked' do
            expect_recipe do
              chef_organization "x" do
                members "invited"
              end
            end.to have_updated("chef_organization[x]", :create)
            expect(get("/organizations/x/users").map { |u| u["user"]["username"] }).to eq(%w{invited member member2})
            expect(get("/organizations/x/association_requests").map { |u| u["username"] }).to eq(%w{invited2})
          end

          it 'chef_organization "x" removes members and invites when asked' do
            expect_recipe do
              chef_organization "x" do
                remove_members "invited", "member"
              end
            end.to have_updated("chef_organization[x]", :create)
            expect(get("/organizations/x/association_requests").map { |u| u["username"] }).to eq(%w{invited2})
            expect(get("/organizations/x/users").map { |u| u["user"]["username"] }).to eq(%w{member2})
          end

          it 'chef_organization "x" does nothing when asked to remove non-members' do
            expect_recipe do
              chef_organization "x" do
                remove_members "u", "u2"
              end
            end.not_to have_updated("chef_organization[x]", :create)
            expect(get("/organizations/x/association_requests").map { |u| u["username"] }).to eq(%w{invited invited2})
            expect(get("/organizations/x/users").map { |u| u["user"]["username"] }).to eq(%w{member member2})
          end

          it 'chef_organization "x" with "complete true" reverts the full_name but does not remove invites or members' do
            expect_recipe do
              chef_organization "x" do
                complete true
              end
            end.to have_updated("chef_organization[x]", :create)
            expect(get("/organizations/x")["full_name"]).to eq("x")
            expect(get("/organizations/x/association_requests").map { |u| u["username"] }).to eq(%w{invited invited2})
            expect(get("/organizations/x/users").map { |u| u["user"]["username"] }).to eq(%w{member member2})
          end

          it 'chef_organization "x" with members [] and "complete true" removes invites and members' do
            expect_recipe do
              chef_organization "x" do
                members []
                complete true
              end
            end.to have_updated("chef_organization[x]", :create)
            expect(get("/organizations/x")["full_name"]).to eq("x")
            expect(get("/organizations/x/association_requests").map { |u| u["username"] }).to eq([])
            expect(get("/organizations/x/users").map { |u| u["user"]["username"] }).to eq([])
          end

          it 'chef_organization "x" with invites [] and "complete true" removes invites but not members' do
            expect_recipe do
              chef_organization "x" do
                invites []
                complete true
              end
            end.to have_updated("chef_organization[x]", :create)
            expect(get("/organizations/x")["full_name"]).to eq("x")
            expect(get("/organizations/x/association_requests").map { |u| u["username"] }).to eq([])
            expect(get("/organizations/x/users").map { |u| u["user"]["username"] }).to eq(%w{member member2})
          end

          it 'chef_organization "x" with invites, members and "complete true" removes all non-specified invites and members' do
            expect_recipe do
              chef_organization "x" do
                invites "invited", "u"
                members "member", "u2"
                complete true
              end
            end.to have_updated("chef_organization[x]", :create)
            expect(get("/organizations/x")["full_name"]).to eq("x")
            expect(get("/organizations/x/association_requests").map { |u| u["username"] }).to eq(%w{invited u})
            expect(get("/organizations/x/users").map { |u| u["user"]["username"] }).to eq(%w{member u2})
          end
        end
      end
    end
  end
end
