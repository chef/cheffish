require 'support/spec_support'
require 'support/key_support'
require 'chef/resource/chef_acl'
require 'chef/provider/chef_acl'

describe Chef::Resource::ChefAcl do
  extend SpecSupport

  context "Rights attributes" do
    when_the_chef_server 'has a node named x', :osc_compat => false do
      node 'x', {}

      it 'Converging chef_acl "nodes/x" changes nothing' do
        expect {
          run_recipe do
            chef_acl 'nodes/x'
          end
        }.to update_acls('nodes/x/_acl', {})
      end

      it 'Converging chef_acl "nodes/x" with "complete true" removes all ACLs' do
        expect {
          run_recipe do
            chef_acl 'nodes/x' do
              complete true
            end
          end
        }.to update_acls('nodes/x/_acl', {
          "create"=>{"actors"=>["-pivotal"], "groups"=>["-admins", "-users", "-clients"]},
          "read"=>{"actors"=>["-pivotal"], "groups"=>["-admins", "-users", "-clients"]},
          "update"=>{"actors"=>["-pivotal"], "groups"=>["-admins", "-users"]},
          "delete"=>{"actors"=>["-pivotal"], "groups"=>["-admins", "-users"]},
          "grant"=>{"actors"=>["-pivotal"], "groups"=>["-admins"]}
        })
      end

      context 'and a user "blarghle"' do
        user 'blarghle', {}

        it 'Converging chef_acl "nodes/x" with user "blarghle" adds the user' do
          expect {
            run_recipe do
              chef_acl 'nodes/x' do
                rights :read, :users => 'blarghle'
              end
            end
          }.to update_acls('nodes/x/_acl', 'read' => { 'actors' => %w(blarghle) })
        end

        it 'Converging chef_acl "nodes/x" with "complete true" removes all ACLs except the user' do
          expect {
            run_recipe do
              chef_acl 'nodes/x' do
                rights :read, :users => 'blarghle'
                complete true
              end
            end
          }.to update_acls('nodes/x/_acl', {
            "create"=>{"actors"=>["-pivotal"], "groups"=>["-admins", "-users", "-clients"]},
            "read"=>{"actors"=>["-pivotal", "blarghle"], "groups"=>["-admins", "-users", "-clients"]},
            "update"=>{"actors"=>["-pivotal"], "groups"=>["-admins", "-users"]},
            "delete"=>{"actors"=>["-pivotal"], "groups"=>["-admins", "-users"]},
            "grant"=>{"actors"=>["-pivotal"], "groups"=>["-admins"]}
          })
        end
      end

      context 'and a client "blarghle"' do
        user 'blarghle', {}

        it 'Converging chef_acl "nodes/x" with client "blarghle" adds the client' do
          expect {
            run_recipe do
              chef_acl 'nodes/x' do
                rights :read, :clients => 'blarghle'
              end
            end
          }.to update_acls('nodes/x/_acl', 'read' => { 'actors' => %w(blarghle) })
        end
      end

      context 'and a group "blarghle"' do
        group 'blarghle', {}

        it 'Converging chef_acl "nodes/x" with group "blarghle" adds the group' do
          expect {
            run_recipe do
              chef_acl 'nodes/x' do
                rights :read, :groups => 'blarghle'
              end
            end
          }.to update_acls('nodes/x/_acl', 'read' => { 'groups' => %w(blarghle) })
        end
      end

      context 'and multiple users and groups' do
        user 'u1', {}
        user 'u2', {}
        user 'u3', {}
        client 'c1', {}
        client 'c2', {}
        client 'c3', {}
        group 'g1', {}
        group 'g2', {}
        group 'g3', {}

        it 'Converging chef_acl "nodes/x" with multiple groups, users and clients in an acl makes the appropriate changes' do
          expect {
            run_recipe do
              chef_acl 'nodes/x' do
                rights :create, :users => [ 'u1', 'u2', 'u3' ], :clients => [ 'c1', 'c2', 'c3' ], :groups => [ 'g1', 'g2', 'g3' ]
              end
            end
          }.to update_acls('nodes/x/_acl',
            'create' => { 'groups' => %w(g1 g2 g3), 'actors' => %w(u1 u2 u3 c1 c2 c3) }
          )
        end

        it 'Converging chef_acl "nodes/x" with multiple groups, users and clients across multiple "rights" groups makes the appropriate changes' do
          expect {
            run_recipe do
              chef_acl 'nodes/x' do
                rights :create, :users => %w(u1), :clients => 'c1', :groups => 'g1'
                rights :create, :users => %w(u2 u3), :clients => %w(c2 c3), :groups => 'g2'
                rights :read, :users => 'u1'
                rights :read, :groups => 'g1'
              end
            end
          }.to update_acls('nodes/x/_acl',
            'create' => { 'groups' => %w(g1 g2), 'actors' => %w(u1 u2 u3 c1 c2 c3) },
            'read' => { 'groups' => %w(g1), 'actors' => %w(u1) }
          )
        end

        it 'Converging chef_acl "nodes/x" with rights [ :read, :create, :update, :delete, :grant ] modifies all rights' do
          expect {
            run_recipe do
              chef_acl 'nodes/x' do
                rights [ :create, :read, :update, :delete, :grant ], :users => %w(u1 u2), :clients => 'c1', :groups => 'g1'
              end
            end
          }.to update_acls('nodes/x/_acl',
            'create' => { 'groups' => %w(g1), 'actors' => %w(u1 u2 c1) },
            'read' => { 'groups' => %w(g1), 'actors' => %w(u1 u2 c1) },
            'update' => { 'groups' => %w(g1), 'actors' => %w(u1 u2 c1) },
            'delete' => { 'groups' => %w(g1), 'actors' => %w(u1 u2 c1) },
            'grant' => { 'groups' => %w(g1), 'actors' => %w(u1 u2 c1) },
          )
        end

        it 'Converging chef_acl "nodes/x" with rights :all modifies all rights' do
          expect {
            run_recipe do
              chef_acl 'nodes/x' do
                rights :all, :users => %w(u1 u2), :clients => 'c1', :groups => 'g1'
              end
            end
          }.to update_acls('nodes/x/_acl',
            'create' => { 'groups' => %w(g1), 'actors' => %w(u1 u2 c1) },
            'read' => { 'groups' => %w(g1), 'actors' => %w(u1 u2 c1) },
            'update' => { 'groups' => %w(g1), 'actors' => %w(u1 u2 c1) },
            'delete' => { 'groups' => %w(g1), 'actors' => %w(u1 u2 c1) },
            'grant' => { 'groups' => %w(g1), 'actors' => %w(u1 u2 c1) },
          )
        end
      end

      it 'Converging chef_acl "nodes/y" throws a 404' do
        expect {
          run_recipe do
            chef_acl 'nodes/y'
          end
        }.to raise_error(Net::HTTPServerException)
      end
    end

    when_the_chef_server 'has a node named x with user blarghle in its acl', :osc_compat => false do
      user 'blarghle', {}
      node 'x', {} do
        acl 'read' => { 'actors' => %w(blarghle) }
      end

      it 'Converging chef_acl "nodes/x" with that user changes nothing' do
        expect {
          run_recipe do
            chef_acl 'nodes/x' do
              rights :read, :users => 'blarghle'
            end
          end
        }.to update_acls('nodes/x/_acl', {})
      end
    end

    when_the_chef_server 'has a node named x with users foo and bar in all its acls', :osc_compat => false do
      user 'foo', {}
      user 'bar', {}
      node 'x', {} do
        acl 'create' => { 'actors' => %w(foo bar) },
            'read' => { 'actors' => %w(foo bar) },
            'update' => { 'actors' => %w(foo bar) },
            'delete' => { 'actors' => %w(foo bar) },
            'grant' => { 'actors' => %w(foo bar) }
      end

      it 'Converging chef_acl "nodes/x" with remove_rights :all removes foo from everything' do
        expect {
          run_recipe do
            chef_acl 'nodes/x' do
              rights :read, :users => 'foo'
            end
          end
        }.to update_acls('nodes/x/_acl',
                         'create' => { 'actors' => %w(-foo) },
                         'read'   => { 'actors' => %w(-foo) },
                         'update' => { 'actors' => %w(-foo) },
                         'delete' => { 'actors' => %w(-foo) },
                         'grant'  => { 'actors' => %w(-foo) },
        )
      end
    end

    context 'recursive' do
      when_the_chef_server 'has a nodes container with user blarghle in its acl', :osc_compat => false do
        user 'blarghle', {}
        acl_for 'containers/nodes', 'read' => { 'actors' => %w(blarghle) }
        node 'x', {} do
          acl 'read' => { 'actors' => [] }
        end

        it 'Converging chef_acl "nodes" makes no changes' do
          expect {
            run_recipe do
              chef_acl 'nodes' do
                rights :read, :users => 'blarghle'
              end
            end
          }.to update_acls([ 'containers/nodes/_acl', 'nodes/x/_acl' ], {})
        end

        it 'Converging chef_acl "nodes" with recursive :on_change makes no changes' do
          expect {
            run_recipe do
              chef_acl 'nodes' do
                rights :read, :users => 'blarghle'
                recursive :on_change
              end
            end
          }.to update_acls([ 'containers/nodes/_acl', 'nodes/x/_acl' ], {})
        end

        it 'Converging chef_acl "nodes" with recursive true changes nodes/x\'s acls' do
          expect {
            run_recipe do
              chef_acl 'nodes' do
                rights :read, :users => 'blarghle'
                recursive true
              end
            end
          }.to update_acls('nodes/x/_acl', 'read' => { 'actors' => %w(blarghle) })
        end

        it 'Converging chef_acl "nodes/**" with recursive false changes nodes/x\'s acls' do
          expect {
            run_recipe do
              chef_acl 'nodes/**' do
                rights :read, :users => 'blarghle'
                recursive false
              end
            end
          }.to update_acls('nodes/x/_acl', 'read' => { 'actors' => %w(blarghle) })
        end

        it 'Converging chef_acl "" with recursive false does not change nodes/x\'s acls' do
          expect {
            run_recipe do
              chef_acl '' do
                rights :read, :users => 'blarghle'
                recursive false
              end
            end
          }.to update_acls([ 'containers/nodes/_acl', 'nodes/x/_acl' ], {})
        end

        it 'Converging chef_acl "" with recursive :on_change does not change nodes/x\'s acls' do
          expect {
            run_recipe do
              chef_acl '' do
                rights :read, :users => 'blarghle'
                recursive :on_change
              end
            end
          }.to update_acls([ 'containers/nodes/_acl', 'nodes/x/_acl' ], {})
        end

        it 'Converging chef_acl "" with recursive true changes nodes/x\'s acls' do
          expect {
            run_recipe do
              chef_acl '' do
                rights :read, :users => 'blarghle'
                recursive true
              end
            end
          }.to update_acls([ 'organizations/_acl', 'nodes/x/_acl' ], 'read' => { 'actors' => %w(blarghle) })
        end

        it 'Converging chef_acl "**" with recursive true changes nodes/x\'s acls' do
          expect {
            run_recipe do
              chef_acl '**' do
                rights :read, :users => 'blarghle'
                recursive true
              end
            end
          }.to update_acls([ 'organizations/_acl', 'nodes/x/_acl' ], 'read' => { 'actors' => %w(blarghle) })
        end
      end
    end
  end

  context 'ACLs on each type of thing' do
    when_the_chef_server 'has an organization named foo', :osc_compat => false, :single_org => false do
      organization 'foo' do
        user 'u', {}
        client 'x', {}
        container 'x', {}
        cookbook 'x', '1.0.0', {}
        data_bag 'x', { 'y' => {} }
        environment 'x', {}
        group 'x', {}
        node 'x', {}
        role 'x', {}
        sandbox 'x', {}
        user 'x', {}
      end

      %w(clients containers cookbooks data environments groups nodes roles sandboxes).each do |type|
        it "chef_acl '/organizations/foo/#{type}/x' changes the acl" do
          expect {
            run_recipe do
              chef_acl "/organizations/foo/#{type}/x" do
                rights :read, :users => 'u'
              end
            end
          }.to update_acls("organizations/foo/#{type}/x/_acl", 'read' => { 'actors' => %w(u) })
        end
      end

      %w(clients containers cookbooks data environments groups nodes roles).each do |type|
        it "chef_acl '/*/*/#{type}/*' changes the acl" do
          expect {
            run_recipe do
              chef_acl "/*/*/#{type}/*" do
                rights :read, :users => 'u'
              end
            end
          }.to update_acls("organizations/foo/#{type}/x/_acl", 'read' => { 'actors' => %w(u) })
        end
      end

      it "chef_acl '/*/*/*/x' changes the acls" do
        expect {
          run_recipe do
            chef_acl "/*/*/*/x" do
              rights :read, :users => 'u'
            end
          end
        }.to update_acls(%w(clients containers cookbooks data environments groups nodes roles sandboxes).map { |type| "organizations/foo/#{type}/x/_acl" },
                         'read' => { 'actors' => %w(u) })
      end

      it "chef_acl '/*/*/*/*' changes the acls" do
        expect {
          run_recipe do
            chef_acl "/*/*/*/*" do
              rights :read, :users => 'u'
            end
          end
        }.to update_acls(%w(clients containers cookbooks data environments groups nodes roles).map { |type| "organizations/foo/#{type}/x/_acl" },
                         'read' => { 'actors' => %w(u) })
      end

      it 'chef_acl "/organizations/foo/data_bags/x" changes the acl' do
        expect {
          run_recipe do
            chef_acl '/organizations/foo/data_bags/x' do
              rights :read, :users => 'u'
            end
          end
        }.to update_acls('organizations/foo/data/x/_acl', 'read' => { 'actors' => %w(u) })
      end

      it 'chef_acl "/*/*/data_bags/*" changes the acl' do
        expect {
          run_recipe do
            chef_acl '/*/*/data_bags/*' do
              rights :read, :users => 'u'
            end
          end
        }.to update_acls('organizations/foo/data/x/_acl', 'read' => { 'actors' => %w(u) })
      end

      it "chef_acl '/organizations/foo/cookbooks/x/1.0.0' raises an error" do
        expect {
          run_recipe do
            chef_acl "/organizations/foo/cookbooks/x/1.0.0" do
              rights :read, :users => 'u'
            end
          end
        }.to raise_error(/ACLs cannot be set on children of \/organizations\/foo\/cookbooks\/x/)
      end

      it "chef_acl '/organizations/foo/cookbooks/*/*' raises an error" do
        pending
        expect {
          run_recipe do
            chef_acl "/organizations/foo/cookbooks/*/*" do
              rights :read, :users => 'u'
            end
          end
        }.to raise_error(/ACLs cannot be set on children of \/organizations\/foo\/cookbooks\/*/)
      end

      it 'chef_acl "/organizations/foo/data/x/y" raises an error' do
        expect {
          run_recipe do
            chef_acl '/organizations/foo/data/x/y' do
              rights :read, :users => 'u'
            end
          end
        }.to raise_error(/ACLs cannot be set on children of \/organizations\/foo\/data\/x/)
      end

      it 'chef_acl "/organizations/foo/data/*/*" raises an error' do
        pending
        expect {
          run_recipe do
            chef_acl '/organizations/foo/data/*/*' do
              rights :read, :users => 'u'
            end
          end
        }.to raise_error(/ACLs cannot be set on children of \/organizations\/foo\/data\/*/)
      end

      it 'chef_acl "/organizations/foo" changes the acl' do
        expect {
          run_recipe do
            chef_acl '/organizations/foo' do
              rights :read, :users => 'u'
            end
          end
        }.to update_acls([ '/organizations/foo/organizations/_acl', '/organizations/foo/nodes/x/_acl' ], 'read' => { 'actors' => %w(u) })
      end

      it 'chef_acl "/organizations/*" changes the acl' do
        expect {
          run_recipe do
            chef_acl '/organizations/*' do
              rights :read, :users => 'u'
            end
          end
        }.to update_acls([ '/organizations/foo/organizations/_acl', '/organizations/foo/nodes/x/_acl' ], 'read' => { 'actors' => %w(u) })
      end

      it 'chef_acl "/users/x" changes the acl' do
        expect {
          run_recipe do
            chef_acl '/users/x' do
              rights :read, :users => 'u'
            end
          end
        }.to update_acls('/users/x/_acl', 'read' => { 'actors' => %w(u) })
      end

      it 'chef_acl "/users/*" changes the acl' do
        expect {
          run_recipe do
            chef_acl '/users/*' do
              rights :read, :users => 'u'
            end
          end
        }.to update_acls('/users/x/_acl', 'read' => { 'actors' => %w(u) })
      end

      it 'chef_acl "/*/x" changes the acl' do
        expect {
          run_recipe do
            chef_acl '/*/x' do
              rights :read, :users => 'u'
            end
          end
        }.to update_acls('/users/x/_acl', 'read' => { 'actors' => %w(u) })
      end

      it 'chef_acl "/*/*" changes the acl' do
        expect {
          run_recipe do
            chef_acl '/*/*' do
              rights :read, :users => 'u'
            end
          end
        }.to update_acls([ '/organizations/foo/organizations/_acl', '/users/x/_acl' ],
                         'read' => { 'actors' => %w(u) })
      end
    end

    when_the_chef_server 'has a user "u" in single org mode', :osc_compat => false do
      user 'u', {}
      client 'x', {}
      container 'x', {}
      cookbook 'x', '1.0.0', {}
      data_bag 'x', { 'y' => {} }
      environment 'x', {}
      group 'x', {}
      node 'x', {}
      role 'x', {}
      sandbox 'x', {}
      user 'x', {}

      %w(clients containers cookbooks data environments groups nodes roles sandboxes).each do |type|
        it "chef_acl #{type}/x' changes the acl" do
          expect {
            run_recipe do
              chef_acl "#{type}/x" do
                rights :read, :users => 'u'
              end
            end
          }.to update_acls("#{type}/x/_acl", 'read' => { 'actors' => %w(u) })
        end
      end

      %w(clients containers cookbooks data environments groups nodes roles).each do |type|
        it "chef_acl '#{type}/*' changes the acl" do
          expect {
            run_recipe do
              chef_acl "#{type}/*" do
                rights :read, :users => 'u'
              end
            end
          }.to update_acls("#{type}/x/_acl", 'read' => { 'actors' => %w(u) })
        end
      end

      it "chef_acl '*/x' changes the acls" do
        expect {
          run_recipe do
            chef_acl "*/x" do
              rights :read, :users => 'u'
            end
          end
        }.to update_acls(%w(clients containers cookbooks data environments groups nodes roles sandboxes).map { |type| "#{type}/x/_acl" },
                         'read' => { 'actors' => %w(u) })
      end

      it "chef_acl '*/*' changes the acls" do
        expect {
          run_recipe do
            chef_acl "*/*" do
              rights :read, :users => 'u'
            end
          end
        }.to update_acls(%w(clients containers cookbooks data environments groups nodes roles).map { |type| "#{type}/x/_acl" },
                         'read' => { 'actors' => %w(u) })
      end

      it "chef_acl 'groups/*' changes the acl" do
        expect {
          run_recipe do
            chef_acl "groups/*" do
              rights :read, :users => 'u'
            end
          end
        }.to update_acls(%w(admins billing-admins clients users x).map { |n| "groups/#{n}/_acl" },
                         'read' => { 'actors' => %w(u) })
      end

      it 'chef_acl "data_bags/x" changes the acl' do
        expect {
          run_recipe do
            chef_acl 'data_bags/x' do
              rights :read, :users => 'u'
            end
          end
        }.to update_acls('data/x/_acl', 'read' => { 'actors' => %w(u) })
      end

      it 'chef_acl "data_bags/*" changes the acl' do
        expect {
          run_recipe do
            chef_acl 'data_bags/*' do
              rights :read, :users => 'u'
            end
          end
        }.to update_acls('data/x/_acl', 'read' => { 'actors' => %w(u) })
      end

      it 'chef_acl "" changes the organization acl' do
        expect {
          run_recipe do
            chef_acl '' do
              rights :read, :users => 'u'
            end
          end
        }.to update_acls([ 'organizations/_acl', 'nodes/x/_acl' ], 'read' => { 'actors' => %w(u) })
      end
    end
  end

  context 'ACLs on each container type' do
    when_the_chef_server 'has an organization named foo', :osc_compat => false, :single_org => false do
      organization 'foo' do
        user 'u', {}
        client 'x', {}
        container 'x', {}
        cookbook 'x', '1.0.0', {}
        data_bag 'x', { 'y' => {} }
        environment 'x', {}
        group 'x', {}
        node 'x', {}
        role 'x', {}
        sandbox 'x', {}
        user 'x', {}
      end

      %w(clients containers cookbooks data environments groups nodes roles sandboxes).each do |type|
        it "chef_acl '/organizations/foo/#{type}' changes the acl" do
          expect {
            run_recipe do
              chef_acl "/organizations/foo/#{type}" do
                rights :read, :users => 'u'
              end
            end
          }.to update_acls("organizations/foo/containers/#{type}/_acl", 'read' => { 'actors' => %w(u) })
        end
      end

      %w(clients containers cookbooks data environments groups nodes roles).each do |type|
        it "chef_acl '/*/*/#{type}' changes the acl" do
          expect {
            run_recipe do
              chef_acl "/*/*/#{type}" do
                rights :read, :users => 'u'
              end
            end
          }.to update_acls("organizations/foo/containers/#{type}/_acl", 'read' => { 'actors' => %w(u) })
        end
      end

      it "chef_acl '/*/*/*' changes the acls" do
        expect {
          run_recipe do
            chef_acl "/*/*/*" do
              rights :read, :users => 'u'
            end
          end
        }.to update_acls(%w(clients containers cookbooks data environments groups nodes roles sandboxes).map { |type| "organizations/foo/containers/#{type}/_acl" },
                         'read' => { 'actors' => %w(u) })
      end

      it 'chef_acl "/organizations/foo/data_bags" changes the acl' do
        expect {
          run_recipe do
            chef_acl '/organizations/foo/data_bags' do
              rights :read, :users => 'u'
            end
          end
        }.to update_acls('organizations/foo/containers/data/_acl', 'read' => { 'actors' => %w(u) })
      end

      it 'chef_acl "/*/*/data_bags" changes the acl' do
        expect {
          run_recipe do
            chef_acl '/*/*/data_bags' do
              rights :read, :users => 'u'
            end
          end
        }.to update_acls('organizations/foo/containers/data/_acl', 'read' => { 'actors' => %w(u) })
      end
    end

    when_the_chef_server 'has a user "u" in single org mode', :osc_compat => false do
      user 'u', {}
      client 'x', {}
      container 'x', {}
      cookbook 'x', '1.0.0', {}
      data_bag 'x', { 'y' => {} }
      environment 'x', {}
      group 'x', {}
      node 'x', {}
      role 'x', {}
      sandbox 'x', {}
      user 'x', {}

      %w(clients containers cookbooks data environments groups nodes roles sandboxes).each do |type|
        it "chef_acl #{type}' changes the acl" do
          expect {
            run_recipe do
              chef_acl "#{type}" do
                rights :read, :users => 'u'
              end
            end
          }.to update_acls("containers/#{type}/_acl", 'read' => { 'actors' => %w(u) })
        end
      end

      it "chef_acl '*' changes the acls" do
        expect {
          run_recipe do
            chef_acl "*" do
              rights :read, :users => 'u'
            end
          end
        }.to update_acls(%w(clients containers cookbooks data environments groups nodes roles sandboxes).map { |type| "containers/#{type}/_acl" },
                         'read' => { 'actors' => %w(u) })
      end
    end
  end

  context 'remove_rights' do
    when_the_chef_server 'has a node "x" with "u", "c" and "g" in its acl', :osc_compat => false do
      user 'u', {}
      user 'u2', {}
      client 'c', {}
      client 'c2', {}
      group 'g', {}
      group 'g2', {}
      node 'x', {} do
        acl 'create' => { 'actors' => [ 'u', 'c' ], 'groups' => [ 'g' ] },
            'read'   => { 'actors' => [ 'u', 'c' ], 'groups' => [ 'g' ] },
            'update' => { 'actors' => [ 'u', 'c' ], 'groups' => [ 'g' ] }
      end

      it 'chef_acl with remove_rights "u" removes the user\'s rights' do
        expect {
          run_recipe do
            chef_acl "nodes/x" do
              remove_rights :read, :users => 'u'
            end
          end
        }.to update_acls("nodes/x/_acl", 'read' => { 'actors' => %w(-u) })
      end

      it 'chef_acl with remove_rights "c" removes the client\'s rights' do
        expect {
          run_recipe do
            chef_acl "nodes/x" do
              remove_rights :read, :clients => 'c'
            end
          end
        }.to update_acls("nodes/x/_acl", 'read' => { 'actors' => %w(-c) })
      end

      it 'chef_acl with remove_rights "g" removes the group\'s rights' do
        expect {
          run_recipe do
            chef_acl "nodes/x" do
              remove_rights :read, :groups => 'g'
            end
          end
        }.to update_acls("nodes/x/_acl", 'read' => { 'groups' => %w(-g) })
      end

      it 'chef_acl with remove_rights [ :create, :read ], "u", "c", "g" removes all three' do
        expect {
          run_recipe do
            chef_acl "nodes/x" do
              remove_rights [ :create, :read ], :users => 'u', :clients => 'c', :groups => 'g'
            end
          end
        }.to update_acls("nodes/x/_acl", 'create' => { 'actors' => %w(-u -c), 'groups' => %w(-g) }, 'read' => { 'actors' => %w(-u -c), 'groups' => %w(-g) })
      end

      it 'chef_acl with remove_rights "u2", "c2", "g2" has no effect' do
        expect {
          run_recipe do
            chef_acl "nodes/x" do
              remove_rights :read, :users => 'u2', :clients => 'c2', :groups => 'g2'
            end
          end
        }.to update_acls("nodes/x/_acl", {})
      end
    end
  end
end
