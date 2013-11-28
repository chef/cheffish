require 'support/spec_support'
require 'cheffish/recipe_dsl'

describe 'Recipe DSL' do
  extend SpecSupport

  when_the_chef_server 'is empty' do
    it 'a recipe that includes with_chef_server and creates node "blah" fails' do
      lambda do
        run_recipe do
          with_chef_server 'http://www.blahdeblahdeblahnowhere.com'
          chef_node 'blah'
        end
      end.should raise_error
    end
  end
end
