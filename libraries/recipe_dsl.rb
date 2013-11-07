class Chef
  class Recipe
    def with_data_bag(name, &block)
      old_enclosing_data_bag = Cheffish.enclosing_data_bag
      Cheffish.enclosing_data_bag = name
      begin
        block.call if block
      ensure
        Cheffish.enclosing_data_bag = old_enclosing_data_bag
      end
    end

    def with_environment(name, &block)
      old_enclosing_environment = Cheffish.enclosing_environment
      Cheffish.enclosing_environment = name
      begin
        block.call if block
      ensure
        Cheffish.enclosing_environment = old_enclosing_environment
      end
    end
  end
end