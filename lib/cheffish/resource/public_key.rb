require 'openssl/cipher'
require 'chef/resource/lwrp_base'
require 'cheffish/provider/public_key'

module Cheffish
  module Resource
    class PublicKey < Chef::Resource::LWRPBase
      self.resource_name = 'public_key'
      provides :public_key
      def provider
        Cheffish::Provider::PublicKey
      end

      actions :create, :delete, :nothing
      default_action :create

      attribute :path, :kind_of => String, :name_attribute => true
      attribute :format, :kind_of => Symbol, :default => :openssh, :equal_to => [ :pem, :der, :openssh ]

      attribute :source, :kind_of => String
      attribute :source_pass_phrase
    end
  end
end
