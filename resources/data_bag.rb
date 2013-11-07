actions :create, :delete, :nothing
default_action :create

attribute :name, :kind_of => String, :regex => Cheffish::NAME_REGEX, :name_attribute => true
