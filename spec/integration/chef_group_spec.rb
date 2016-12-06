require "support/spec_support"
require "cheffish/rspec/chef_run_support"

describe Chef::Resource::ChefGroup do
  extend Cheffish::RSpec::ChefRunSupport

  when_the_chef_12_server "is in multi-org mode" do
    organization "foo"

    before :each do
      Chef::Config.chef_server_url = URI.join(Chef::Config.chef_server_url, "/organizations/foo").to_s
    end

    context "and is empty" do
      group "g", {}
      user "u", {}
      client "c", {}

      it 'Converging chef_group "x" creates the group with no members' do
        expect_recipe do
          chef_group "x"
        end.to have_updated("chef_group[x]", :create)
        expect(get("groups/x")).to eq({
          "name" => "x",
          "groupname" => "x",
          "orgname" => "foo",
          "actors"  => [],
          "groups"  => [],
          "users"   => [],
          "clients" => [],
        })
      end

      it 'chef_group "x" action :delete does nothing' do
        expect_recipe do
          chef_group "x" do
            action :delete
          end
        end.to not_have_updated("chef_group[x]", :delete).and not_have_updated("chef_group[x]", :create)
        expect { get("groups/x") }.to raise_error(Net::HTTPServerException)
      end

      it 'Converging chef_group "x" creates the group with the given members' do
        expect_recipe do
          chef_group "x" do
            groups "g"
            users "u"
            clients "c"
          end
        end.to have_updated("chef_group[x]", :create)
        expect(get("groups/x")).to eq({
          "name" => "x",
          "groupname" => "x",
          "orgname" => "foo",
          "actors"  => %w{c u},
          "groups"  => %w{g},
          "users"   => %w{u},
          "clients" => %w{c},
        })
      end
    end

    context "and has a group named x" do
      group "g", {}
      group "g2", {}
      group "g3", {}
      group "g4", {}
      user "u", {}
      user "u2", {}
      user "u3", {}
      user "u4", {}
      client "c", {}
      client "c2", {}
      client "c3", {}
      client "c4", {}

      group "x", {
        "users" => %w{u u2},
        "clients" => %w{c c2},
        "groups" => %w{g g2},
      }

      it 'Converging chef_group "x" changes nothing' do
        expect_recipe do
          chef_group "x"
        end.not_to have_updated("chef_group[x]", :create)
        expect(get("groups/x")).to eq({
          "name" => "x",
          "groupname" => "x",
          "orgname" => "foo",
          "actors"  => %w{c c2 u u2},
          "groups"  => %w{g g2},
          "users"   => %w{u u2},
          "clients" => %w{c c2},
        })
      end

      it 'chef_group "x" action :delete deletes the group' do
        expect_recipe do
          chef_group "x" do
            action :delete
          end
        end.to have_updated("chef_group[x]", :delete)
        expect { get("groups/x") }.to raise_error(Net::HTTPServerException)
      end

      it 'Converging chef_group "x" with existing users changes nothing' do
        expect_recipe do
          chef_group "x" do
            users "u"
            clients "c"
            groups "g"
          end
        end.not_to have_updated("chef_group[x]", :create)
        expect(get("groups/x")).to eq({
          "name" => "x",
          "groupname" => "x",
          "orgname" => "foo",
          "actors"  => %w{c c2 u u2},
          "groups"  => %w{g g2},
          "users"   => %w{u u2},
          "clients" => %w{c c2},
        })
      end

      it 'Converging chef_group "x" adds new users' do
        expect_recipe do
          chef_group "x" do
            users "u3"
            clients "c3"
            groups "g3"
          end
        end.to have_updated("chef_group[x]", :create)
        expect(get("groups/x")).to eq({
          "name" => "x",
          "groupname" => "x",
          "orgname" => "foo",
          "actors"  => %w{c c2 c3 u u2 u3},
          "groups"  => %w{g g2 g3},
          "users"   => %w{u u2 u3},
          "clients" => %w{c c2 c3},
        })
      end

      it 'Converging chef_group "x" with multiple users adds new users' do
        expect_recipe do
          chef_group "x" do
            users "u3", "u4"
            clients "c3", "c4"
            groups "g3", "g4"
          end
        end.to have_updated("chef_group[x]", :create)
        expect(get("groups/x")).to eq({
          "name" => "x",
          "groupname" => "x",
          "orgname" => "foo",
          "actors"  => %w{c c2 c3 c4 u u2 u3 u4},
          "groups"  => %w{g g2 g3 g4},
          "users"   => %w{u u2 u3 u4},
          "clients" => %w{c c2 c3 c4},
        })
      end

      it 'Converging chef_group "x" with multiple users in an array adds new users' do
        expect_recipe do
          chef_group "x" do
            users %w{u3 u4}
            clients %w{c3 c4}
            groups %w{g3 g4}
          end
        end.to have_updated("chef_group[x]", :create)
        expect(get("groups/x")).to eq({
          "name" => "x",
          "groupname" => "x",
          "orgname" => "foo",
          "actors"  => %w{c c2 c3 c4 u u2 u3 u4},
          "groups"  => %w{g g2 g3 g4},
          "users"   => %w{u u2 u3 u4},
          "clients" => %w{c c2 c3 c4},
        })
      end

      it 'Converging chef_group "x" with multiple users declarations adds new users' do
        expect_recipe do
          chef_group "x" do
            users "u3"
            users "u4"
            clients "c3"
            clients "c4"
            groups "g3"
            groups "g4"
          end
        end.to have_updated("chef_group[x]", :create)
        expect(get("groups/x")).to eq({
          "name" => "x",
          "groupname" => "x",
          "orgname" => "foo",
          "actors"  => %w{c c2 c3 c4 u u2 u3 u4},
          "groups"  => %w{g g2 g3 g4},
          "users"   => %w{u u2 u3 u4},
          "clients" => %w{c c2 c3 c4},
        })
      end

      it 'Converging chef_group "x" removes desired users' do
        expect_recipe do
          chef_group "x" do
            remove_users "u2"
            remove_clients "c2"
            remove_groups "g2"
          end
        end.to have_updated("chef_group[x]", :create)
        expect(get("groups/x")).to eq({
          "name" => "x",
          "groupname" => "x",
          "orgname" => "foo",
          "actors"  => %w{c u},
          "groups"  => %w{g},
          "users"   => %w{u},
          "clients" => %w{c},
        })
      end

      it 'Converging chef_group "x" with multiple users removes desired users' do
        expect_recipe do
          chef_group "x" do
            remove_users "u", "u2"
            remove_clients "c", "c2"
            remove_groups "g", "g2"
          end
        end.to have_updated("chef_group[x]", :create)
        expect(get("groups/x")).to eq({
          "name" => "x",
          "groupname" => "x",
          "orgname" => "foo",
          "actors"  => [],
          "groups"  => [],
          "users"   => [],
          "clients" => [],
        })
      end

      it 'Converging chef_group "x" with multiple users in an array removes desired users' do
        expect_recipe do
          chef_group "x" do
            remove_users %w{u u2}
            remove_clients %w{c c2}
            remove_groups %w{g g2}
          end
        end.to have_updated("chef_group[x]", :create)
        expect(get("groups/x")).to eq({
          "name" => "x",
          "groupname" => "x",
          "orgname" => "foo",
          "actors"  => [],
          "groups"  => [],
          "users"   => [],
          "clients" => [],
        })
      end

      it 'Converging chef_group "x" with multiple remove_ declarations removes desired users' do
        expect_recipe do
          chef_group "x" do
            remove_users "u"
            remove_users "u2"
            remove_clients "c"
            remove_clients "c2"
            remove_groups "g"
            remove_groups "g2"
          end
        end.to have_updated("chef_group[x]", :create)
        expect(get("groups/x")).to eq({
          "name" => "x",
          "groupname" => "x",
          "orgname" => "foo",
          "actors"  => [],
          "groups"  => [],
          "users"   => [],
          "clients" => [],
        })
      end

      it 'Converging chef_group "x" adds and removes desired users' do
        expect_recipe do
          chef_group "x" do
            users "u3"
            clients "c3"
            groups "g3"
            remove_users "u"
            remove_clients "c"
            remove_groups "g"
          end
        end.to have_updated("chef_group[x]", :create)
        expect(get("groups/x")).to eq({
          "name" => "x",
          "groupname" => "x",
          "orgname" => "foo",
          "actors"  => %w{c2 c3 u2 u3},
          "groups"  => %w{g2 g3},
          "users"   => %w{u2 u3},
          "clients" => %w{c2 c3},
        })
      end
    end
  end
end
