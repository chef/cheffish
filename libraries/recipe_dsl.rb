class Chef
  class Recipe
    def with_chef_data_bag(name)
      old_enclosing_data_bag = Cheffish.enclosing_data_bag
      Cheffish.enclosing_data_bag = name
      if block_given?
        begin
          yield
        ensure
          Cheffish.enclosing_data_bag = old_enclosing_data_bag
        end
      end
    end

    def with_chef_environment(name)
      old_enclosing_environment = Cheffish.enclosing_environment
      Cheffish.enclosing_environment = name
      if block_given?
        begin
          yield
        ensure
          Cheffish.enclosing_environment = old_enclosing_environment
        end
      end
    end

    def with_chef_data_bag_item_encryption(encryption_options)
      old_enclosing_data_bag_item_encryption = Cheffish.enclosing_data_bag_item_encryption
      Cheffish.enclosing_data_bag_item_encryption = encryption_options
      if block_given?
        begin
          yield
        ensure
          Cheffish.enclosing_data_bag_item_encryption = old_enclosing_data_bag_item_encryption
        end
      end
    end

    def with_bootstrapper(bootstrapper)
      old_bootstrapper = Cheffish.enclosing_bootstrapper
      Cheffish.enclosing_bootstrapper = bootstrapper
      if block_given?
        begin
          yield
        ensure
          Cheffish.enclosing_bootstrapper = old_bootstrapper
        end
      end
    end
  end
end
