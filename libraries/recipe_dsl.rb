class Chef
  class Recipe
    def with_data_bag(name, &block)
      old_enclosing_data_bag = Cheffish.enclosing_data_bag
      Cheffish.enclosing_data_bag = name
      if block
        begin
          block.call
        ensure
          Cheffish.enclosing_data_bag = old_enclosing_data_bag
        end
      end
    end

    def with_environment(name, &block)
      old_enclosing_environment = Cheffish.enclosing_environment
      Cheffish.enclosing_environment = name
      if block
        begin
          block.call
        ensure
          Cheffish.enclosing_environment = old_enclosing_environment
        end
      end
    end

    def with_data_bag_item_encryption(encryption_options, &block)
      old_enclosing_data_bag_item_encryption = Cheffish.enclosing_data_bag_item_encryption
      Cheffish.enclosing_data_bag_item_encryption = encryption_options
      if block
        begin
          block.call
        ensure
          Cheffish.enclosing_data_bag_item_encryption = old_enclosing_data_bag_item_encryption
        end
      end
    end
  end
end