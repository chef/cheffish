require 'cheffish'
require 'chef/config'
require 'chef/resource/lwrp_base'

class Chef::Resource::ChefDataBagItem < Chef::Resource::LWRPBase
  self.resource_name = 'chef_data_bag_item'

  actions :create, :delete, :nothing
  default_action :create

  def initialize(*args)
    super
    name @name
    if !data_bag
      data_bag run_context.cheffish.current_data_bag
    end
    if run_context.cheffish.current_data_bag_item_encryption
      @encrypt = true if run_context.cheffish.current_data_bag_item_encryption[:encrypt_all]
      @secret = run_context.cheffish.current_data_bag_item_encryption[:secret]
      @secret_path = run_context.cheffish.current_data_bag_item_encryption[:secret_path] || run_context.config[:encrypted_data_bag_secret]
      @encryption_cipher = run_context.cheffish.current_data_bag_item_encryption[:encryption_cipher]
      @encryption_version = run_context.cheffish.current_data_bag_item_encryption[:encryption_version] || run_context.config[:data_bag_encrypt_version]
      @old_secret = run_context.cheffish.current_data_bag_item_encryption[:old_secret]
      @old_secret_path = run_context.cheffish.current_data_bag_item_encryption[:old_secret_path]
    end
    chef_server run_context.cheffish.current_chef_server
  end

  def name(*args)
    result = super(*args)
    if args.size == 1
      parts = name.split('/')
      if parts.size == 1
        @id = parts[0]
      elsif parts.size == 2
        @data_bag = parts[0]
        @id = parts[1]
      else
        raise "Name #{args[0].inspect} must be a string with 1 or 2 parts, either 'id' or 'data_bag/id"
      end
    end
    result
  end

  NOT_PASSED = Object.new
  def id(value = NOT_PASSED)
    if value == NOT_PASSED
      @id
    else
      @id = value
      name data_bag ? "#{data_bag}/#{id}" : id
    end
  end
  def data_bag(value = NOT_PASSED)
    if value == NOT_PASSED
      @data_bag
    else
      @data_bag = value
      name data_bag ? "#{data_bag}/#{id}" : id
    end
  end
  attribute :raw_data, :kind_of => Hash

  # If secret or secret_path are set, encrypt is assumed true.  encrypt exists mainly for with_secret and with_secret_path
  attribute :encrypt, :kind_of => [TrueClass, FalseClass]
  #attribute :secret, :kind_of => String
  def secret(new_secret = nil)
    if !new_secret
      @secret
    else
      @secret = new_secret
      @encrypt = true if @encrypt.nil?
    end
  end
  #attribute :secret_path, :kind_of => String
  def secret_path(new_secret_path = nil)
    if !new_secret_path
      @secret_path
    else
      @secret_path = new_secret_path
      @encrypt = true if @encrypt.nil?
    end
  end
  attribute :encryption_version, :kind_of => Integer

  # Old secret (or secrets) to read the old data bag when we are changing keys and re-encrypting data
  attribute :old_secret, :kind_of => [String, Array]
  attribute :old_secret_path, :kind_of => [String, Array]

  # Specifies that this is a complete specification for the environment (i.e. attributes you don't specify will be
  # reset to their defaults)
  attribute :complete, :kind_of => [TrueClass, FalseClass]

  attribute :raw_json, :kind_of => Hash
  attribute :chef_server, :kind_of => Hash

  # value 'ip_address', '127.0.0.1'
  # value [ 'pushy', 'port' ], '9000'
  # value 'ip_addresses' do |existing_value|
  #   (existing_value || []) + [ '127.0.0.1' ]
  # end
  # value 'ip_address', :delete
  attr_reader :raw_data_modifiers
  def value(raw_data_path, value=NOT_PASSED, &block)
    @raw_data_modifiers ||= []
    if value != NOT_PASSED
      @raw_data_modifiers << [ raw_data_path, value ]
    elsif block
      @raw_data_modifiers << [ raw_data_path, block ]
    else
      raise "value requires either a value or a block"
    end
  end
end
