module Cheffish
  NAME_REGEX = /^[.\-[:alnum:]_]+$/

  @@enclosing_data_bag = nil
  def self.enclosing_data_bag
    @@enclosing_data_bag
  end
  def self.enclosing_data_bag=(name)
    @@enclosing_data_bag = name
  end

  @@enclosing_environment = nil
  def self.enclosing_environment
    @@enclosing_environment
  end
  def self.enclosing_environment=(name)
    @@enclosing_environment = name
  end
end
