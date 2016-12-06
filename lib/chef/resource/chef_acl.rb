require "cheffish"
require "cheffish/base_resource"
require "chef/chef_fs/data_handler/acl_data_handler"
require "chef/chef_fs/parallelizer"
require "uri"

class Chef
  class Resource
    class ChefAcl < Cheffish::BaseResource
      resource_name :chef_acl

      # Path of the thing being secured, e.g. nodes, nodes/*, nodes/mynode,
      # */*, **, roles/base, data/secrets, cookbooks/apache2, /users/*,
      # /organizations/foo/nodes/x
      property :path, String, name_property: true

      # Whether to change things recursively.  true means it will descend all children
      # and make the same modifications to them.  :on_change will only descend if
      # the parent has changed.  :on_change is the default.
      property :recursive, [ true, false, :on_change ], default: :on_change

      # rights :read, :users => 'jkeiser', :groups => [ 'admins', 'users' ]
      # rights [ :create, :read ], :users => [ 'jkeiser', 'adam' ]
      # rights :all, :users => 'jkeiser'
      def rights(*values)
        if values.size == 0
          @rights
        else
          args = values.pop
          args[:permissions] ||= []
          values.each do |value|
            args[:permissions] |= Array(value)
          end
          @rights ||= []
          @rights << args
        end
      end

      # remove_rights :read, :users => 'jkeiser', :groups => [ 'admins', 'users' ]
      # remove_rights [ :create, :read ], :users => [ 'jkeiser', 'adam' ]
      # remove_rights :all, :users => [ 'jkeiser', 'adam' ]
      def remove_rights(*values)
        if values.size == 0
          @remove_rights
        else
          args = values.pop
          args[:permissions] ||= []
          values.each do |value|
            args[:permissions] |= Array(value)
          end
          @remove_rights ||= []
          @remove_rights << args
        end
      end

      action :create do
        if new_resource.remove_rights && new_resource.complete
          Chef::Log.warn("'remove_rights' is redundant when 'complete' is specified: all rights not specified in a 'rights' declaration will be removed.")
        end
        # Verify that we're not destroying all hope of ACL recovery here
        if new_resource.complete && (!new_resource.rights || !new_resource.rights.any? { |r| r[:permissions].include?(:all) || r[:permissions].include?(:grant) })
          # NOTE: if superusers exist, this should turn into a warning.
          raise "'complete' specified on chef_acl resource, but no GRANT permissions were granted.  I'm sorry Dave, I can't let you remove all access to an object with no hope of recovery."
        end

        # Find all matching paths so we can update them (resolve * and **)
        paths = match_paths(new_resource.path)
        if paths.size == 0 && !new_resource.path.split("/").any? { |p| p == "*" }
          raise "Path #{new_resource.path} cannot have an ACL set on it!"
        end

        # Go through the matches and update the ACLs for them
        paths.each do |path|
          create_acl(path)
        end
      end

      action_class.class_eval do
        # Update the ACL if necessary.
        def create_acl(path)
          changed = false
          # There may not be an ACL path for some valid paths (/ and /organizations,
          # for example).  We want to recurse into these, but we don't want to try to
          # update nonexistent ACLs for them.
          acl = acl_path(path)
          if acl
            # It's possible to make a custom container
            current_json = current_acl(acl)
            if current_json

              # Compare the desired and current json for the ACL, and update if different.
              modify = {}
              desired_acl(acl).each do |permission, desired_json|
                differences = json_differences(sort_values(current_json[permission]), sort_values(desired_json))

                if differences.size > 0
                  # Verify we aren't trying to destroy grant permissions
                  if permission == "grant" && desired_json["actors"] == [] && desired_json["groups"] == []
                    # NOTE: if superusers exist, this should turn into a warning.
                    raise "chef_acl attempted to remove all actors from GRANT!  I'm sorry Dave, I can't let you remove access to an object with no hope of recovery."
                  end
                  modify[differences] ||= {}
                  modify[differences][permission] = desired_json
                end
              end

              if modify.size > 0
                changed = true
                description = [ "update acl #{path} at #{rest_url(path)}" ] + modify.flat_map do |diffs, permissions|
                  diffs.map { |diff| "  #{permissions.keys.join(', ')}:#{diff}" }
                end
                converge_by description do
                  modify.values.each do |permissions|
                    permissions.each do |permission, desired_json|
                      rest.put(rest_url("#{acl}/#{permission}"), { permission => desired_json })
                    end
                  end
                end
              end
            end
          end

          # If we have been asked to recurse, do so.
          # If recurse is on_change, then we will recurse if there is no ACL, or if
          # the ACL has changed.
          if new_resource.recursive == true || (new_resource.recursive == :on_change && (!acl || changed))
            children, error = list(path, "*")
            Chef::ChefFS::Parallelizer.parallel_do(children) do |child|
              next if child.split("/")[-1] == "containers"
              create_acl(child)
            end
            # containers mess up our descent, so we do them last
            Chef::ChefFS::Parallelizer.parallel_do(children) do |child|
              next if child.split("/")[-1] != "containers"
              create_acl(child)
            end

          end
        end

        # Get the current ACL for the given path
        def current_acl(acl_path)
          @current_acls ||= {}
          if !@current_acls.has_key?(acl_path)
            @current_acls[acl_path] = begin
              rest.get(rest_url(acl_path))
            rescue Net::HTTPServerException => e
              unless e.response.code == "404" && new_resource.path.split("/").any? { |p| p == "*" }
                raise
              end
            end
          end
          @current_acls[acl_path]
        end

        # Get the desired acl for the given acl path
        def desired_acl(acl_path)
          result = new_resource.raw_json ? new_resource.raw_json.dup : {}

          # Calculate the JSON based on rights
          add_rights(acl_path, result)

          if new_resource.complete
            result = Chef::ChefFS::DataHandler::AclDataHandler.new.normalize(result, nil)
          else
            # If resource is incomplete, use current json to fill any holes
            current_acl(acl_path).each do |permission, perm_hash|
              if !result[permission]
                result[permission] = perm_hash.dup
              else
                result[permission] = result[permission].dup
                perm_hash.each do |type, actors|
                  if !result[permission][type]
                    result[permission][type] = actors
                  else
                    result[permission][type] = result[permission][type].dup
                    result[permission][type] |= actors
                  end
                end
              end
            end

            remove_rights(result)
          end
          result
        end

        def sort_values(json)
          json.each do |key, value|
            json[key] = value.sort if value.is_a?(Array)
          end
          json
        end

        def add_rights(acl_path, json)
          if new_resource.rights
            new_resource.rights.each do |rights|
              if rights[:permissions].delete(:all)
                rights[:permissions] |= current_acl(acl_path).keys
              end

              Array(rights[:permissions]).each do |permission|
                ace = json[permission.to_s] ||= {}
                # WTF, no distinction between users and clients?  The Chef API doesn't
                # let us distinguish, so we have no choice :/  This means that:
                # 1. If you specify :users => 'foo', and client 'foo' exists, it will
                #    pick that (whether user 'foo' exists or not)
                # 2. If you specify :clients => 'foo', and user 'foo' exists but
                #    client 'foo' does not, it will pick user 'foo' and put it in the
                #    ACL
                # 3. If an existing item has user 'foo' on it and you specify :clients
                #    => 'foo' instead, idempotence will not notice that anything needs
                #    to be updated and nothing will happen.
                if rights[:users]
                  ace["actors"] ||= []
                  ace["actors"] |= Array(rights[:users])
                end
                if rights[:clients]
                  ace["actors"] ||= []
                  ace["actors"] |= Array(rights[:clients])
                end
                if rights[:groups]
                  ace["groups"] ||= []
                  ace["groups"] |= Array(rights[:groups])
                end
              end
            end
          end
        end

        def remove_rights(json)
          if new_resource.remove_rights
            new_resource.remove_rights.each do |rights|
              rights[:permissions].each do |permission|
                if permission == :all
                  json.each_key do |key|
                    ace = json[key] = json[key.dup]
                    ace["actors"] = ace["actors"] - Array(rights[:users])   if rights[:users]   && ace["actors"]
                    ace["actors"] = ace["actors"] - Array(rights[:clients]) if rights[:clients] && ace["actors"]
                    ace["groups"] = ace["groups"] - Array(rights[:groups])  if rights[:groups]  && ace["groups"]
                  end
                else
                  ace = json[permission.to_s] = json[permission.to_s].dup
                  if ace
                    ace["actors"] = ace["actors"] - Array(rights[:users])   if rights[:users]   && ace["actors"]
                    ace["actors"] = ace["actors"] - Array(rights[:clients]) if rights[:clients] && ace["actors"]
                    ace["groups"] = ace["groups"] - Array(rights[:groups])  if rights[:groups]  && ace["groups"]
                  end
                end
              end
            end
          end
        end

        def load_current_resource
        end

        #
        # Matches chef_acl paths like nodes, nodes/*.
        #
        # == Examples
        # match_paths('nodes'): [ 'nodes' ]
        # match_paths('nodes/*'): [ 'nodes/x', 'nodes/y', 'nodes/z' ]
        # match_paths('*'): [ 'clients', 'environments', 'nodes', 'roles', ... ]
        # match_paths('/'): [ '/' ]
        # match_paths(''): [ '' ]
        # match_paths('/*'): [ '/organizations', '/users' ]
        # match_paths('/organizations/*/*'): [ '/organizations/foo/clients', '/organizations/foo/environments', ..., '/organizations/bar/clients', '/organizations/bar/environments', ... ]
        #
        def match_paths(path)
          # Turn multiple slashes into one
          # nodes//x -> nodes/x
          path = path.gsub(/[\/]+/, "/")
          # If it's absolute, start the matching with /.  If it's relative, start with '' (relative root).
          if path[0] == "/"
            matches = [ "/" ]
          else
            matches = [ "" ]
          end

          # Split the path, and get rid of the empty path at the beginning and end
          # (/a/b/c/ -> [ 'a', 'b', 'c' ])
          parts = path.split("/").select { |x| x != "" }.to_a

          # Descend until we find the matches:
          # path = 'a/b/c'
          # parts = [ 'a', 'b', 'c' ]
          # Starting matches = [ '' ]
          parts.each_with_index do |part, index|
            # For each match, list <match>/<part> and set matches to that.
            #
            # Example: /*/foo
            # 1. To start,
            #    matches = [ '/' ], part = '*'.
            #    list('/', '*')                = [ '/organizations, '/users' ]
            # 2. matches = [ '/organizations', '/users' ], part = 'foo'
            #    list('/organizations', 'foo') = [ '/organizations/foo' ]
            #    list('/users', 'foo')         = [ '/users/foo' ]
            #
            # Result: /*/foo = [ '/organizations/foo', '/users/foo' ]
            #
            matches = Chef::ChefFS::Parallelizer.parallelize(matches) do |path|
              found, error = list(path, part)
              if error
                if parts[0..index - 1].all? { |p| p != "*" }
                  raise error
                end
                []
              else
                found
              end
            end.flatten(1).to_a
          end

          matches
        end

        #
        # Takes a normal path and finds the Chef path to get / set its ACL.
        #
        # nodes/x -> nodes/x/_acl
        # nodes -> containers/nodes/_acl
        # '' -> organizations/_acl (the org acl)
        # /organizations/foo -> /organizations/foo/organizations/_acl
        # /users/foo -> /users/foo/_acl
        # /organizations/foo/nodes/x -> /organizations/foo/nodes/x/_acl
        #
        def acl_path(path)
          parts = path.split("/").select { |x| x != "" }.to_a
          prefix = (path[0] == "/") ? "/" : ""

          case parts.size
          when 0
            # /, empty (relative root)
            # The root of the server has no publicly visible ACLs.  Only nodes/*, etc.
            if prefix == ""
              ::File.join("organizations", "_acl")
            end

          when 1
            # nodes, roles, etc.
            # The top level organizations and users containers have no publicly
            # visible ACLs.  Only nodes/*, etc.
            if prefix == ""
              ::File.join("containers", path, "_acl")
            end

          when 2
            # /organizations/NAME, /users/NAME, nodes/NAME, roles/NAME, etc.
            if prefix == "/" && parts[0] == "organizations"
              ::File.join(path, "organizations", "_acl")
            else
              ::File.join(path, "_acl")
            end

          when 3
            # /organizations/NAME/nodes, cookbooks/NAME/VERSION, etc.
            if prefix == "/"
              ::File.join("/", parts[0], parts[1], "containers", parts[2], "_acl")
            else
              ::File.join(parts[0], parts[1], "_acl")
            end

          when 4
            # /organizations/NAME/nodes/NAME, cookbooks/NAME/VERSION/BLAH
            # /organizations/NAME/nodes/NAME, cookbooks/NAME/VERSION, etc.
            if prefix == "/"
              ::File.join(path, "_acl")
            else
              ::File.join(parts[0], parts[1], "_acl")
            end

          else
            # /organizations/NAME/cookbooks/NAME/VERSION/..., cookbooks/NAME/VERSION/A/B/...
            if prefix == "/"
              ::File.join("/", parts[0], parts[1], parts[2], parts[3], "_acl")
            else
              ::File.join(parts[0], parts[1], "_acl")
            end
          end
        end

        #
        # Lists the securable children under a path (the ones that either have ACLs
        # or have children with ACLs).
        #
        # list('nodes', 'x') -> [ 'nodes/x' ]
        # list('nodes', '*') -> [ 'nodes/x', 'nodes/y', 'nodes/z' ]
        # list('', '*') -> [ 'clients', 'environments', 'nodes', 'roles', ... ]
        # list('/', '*') -> [ '/organizations']
        # list('cookbooks', 'x') -> [ 'cookbooks/x' ]
        # list('cookbooks/x', '*') -> [ ] # Individual cookbook versions do not have their own ACLs
        # list('/organizations/foo/nodes', '*') -> [ '/organizations/foo/nodes/x', '/organizations/foo/nodes/y' ]
        #
        # The list of children of an organization is == the list of containers.  If new
        # containers are added, the list of children will grow.  This allows the system
        # to extend to new types of objects and allow cheffish to work with them.
        #
        def list(path, child)
          # TODO make ChefFS understand top level organizations and stop doing this altogether.
          parts = path.split("/").select { |x| x != "" }.to_a
          absolute = (path[0] == "/")
          if absolute && parts[0] == "organizations"
            return [ [], "ACLs cannot be set on children of #{path}" ] if parts.size > 3
          else
            return [ [], "ACLs cannot be set on children of #{path}" ] if parts.size > 1
          end

          error = nil

          if child == "*"
            case parts.size
            when 0
              # /*, *
              if absolute
                results = [ "/organizations", "/users" ]
              else
                results, error = rest_list("containers")
              end

            when 1
              # /organizations/*, /users/*, roles/*, nodes/*, etc.
              results, error = rest_list(path)
              if !error
                results = results.map { |result| ::File.join(path, result) }
              end

            when 2
              # /organizations/NAME/*
              results, error = rest_list(::File.join(path, "containers"))
              if !error
                results = results.map { |result| ::File.join(path, result) }
              end

            when 3
              # /organizations/NAME/TYPE/*
              results, error = rest_list(path)
              if !error
                results = results.map { |result| ::File.join(path, result) }
              end
            end

          else
            if child == "data_bags" &&
                (parts.size == 0 || (parts.size == 2 && parts[0] == "organizations"))
              child = "data"
            end

            if absolute
              # /<child>, /users/<child>, /organizations/<child>, /organizations/foo/<child>, /organizations/foo/nodes/<child> ...
              results = [ ::File.join("/", parts[0..2], child) ]
            elsif parts.size == 0
              # <child> (nodes, roles, etc.)
              results = [ child ]
            else
              # nodes/<child>, roles/<child>, etc.
              results = [ ::File.join(parts[0], child) ]
            end
          end

          [ results, error ]
        end

        def rest_url(path)
          path[0] == "/" ? URI.join(rest.url, path) : path
        end

        def rest_list(path)
          begin
            # All our rest lists are hashes where the keys are the names
            [ rest.get(rest_url(path)).keys, nil ]
          rescue Net::HTTPServerException => e
            if e.response.code == "405" || e.response.code == "404"
              parts = path.split("/").select { |p| p != "" }.to_a

              # We KNOW we expect these to exist.  Other containers may or may not.
              unless (parts.size == 1 || (parts.size == 3 && parts[0] == "organizations")) &&
                  %w{clients containers cookbooks data environments groups nodes roles}.include?(parts[-1])
                return [ [], "Cannot get list of #{path}: HTTP response code #{e.response.code}" ]
              end
            end
            raise
          end
        end
      end

    end
  end
end
