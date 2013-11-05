action :create do
  create_keys(false)
end

action :regenerate do
  create_keys(true)
end

action :delete do
  if Array(current_resource.action) == [ :create ]
    converge_by "delete private key #{new_resource.path}" do
      File.unlink(new_resource.path)
    end
  end
  if current_resource.public_key_path && File.exist?(new_resource.public_key_path)
    converge_by "delete public key #{new_resource.public_key_path}" do
      File.unlink(new_resource.public_key_path)
    end
  end
end

require 'openssl'

def whyrun_supported?
  true
end

def create_keys(regenerate)
  #
  # Create private key file
  #
  if Array(current_resource.action) == [ :delete ] || regenerate
    action = ::File.exists?(current_resource.path) ? "overwrite" : "create"
    converge_by "#{action} #{new_resource.type} private key #{new_resource.path} (#{new_resource.size} bits#{new_resource.pass_phrase ? ", #{new_resource.cipher} password" : ""})" do
      case new_resource.type
      when :rsa
        if new_resource.exponent
          pkey = OpenSSL::PKey::RSA.generate(new_resource.size, new_resource.exponent)
        else
          pkey = OpenSSL::PKey::RSA.generate(new_resource.size)
        end
      when :dsa
        pkey = OpenSSL::PKey::DSA.generate(new_resource.size)
      end

      case new_file_type
      when :pem
        if new_resource.pass_phrase
          private_key_contents = pkey.to_pem(OpenSSL::Cipher.new(new_resource.cipher), new_resource.pass_phrase)
        else
          private_key_contents = pkey.to_pem
        end
      when :der
        private_key_contents = pkey.to_der
      end

      ::File.open(new_resource.path, 'w') do |file|
        file.write(private_key_contents)
      end
    end
    regenerate = true # We will be regenerating the public key if we regenerated the private key
  else
    # TODO verify the existing key's attributes do not mismatch.  Exit if they do!
  end

  #
  # Create public key file
  #
  if new_resource.public_key_path
    if !current_resource.public_key_path || regenerate
      action = ::File.exist?(new_resource.public_key_path) ? "overwrite" : "create"
      converge_by "#{action} #{new_resource.type} public key #{new_resource.public_key_path}" do
        ::File.open(new_resource.path) do |private_key_file|
          pkey = OpenSSL::PKey.read(private_key_file, new_resource.pass_phrase)

          case new_file_type
          when :pem
            public_key_contents = pkey.to_pem
          when :der
            public_key_contents = pkey.to_der
          end

          ::File.open(new_resource.public_key_path, 'w') do |file|
            file.write(public_key_contents)
          end
        end
      end
    else
      # TODO verify stuff--at LEAST verify that it matches the pem in the private key file
    end
  end
end

def new_file_type
  new_resource.file_type || (new_resource.path =~ /.der$/ ? :der : :pem)
end

def load_current_resource
  if ::File.exist?(new_resource.path)
    ::File.open(new_resource.path) do |private_key_file|
      pkey = OpenSSL::PKey.read(private_key_file, new_resource.pass_phrase)
      resource = Chef::Resource::CheffishPrivateKey.new(new_resource.path)
      if new_resource.public_key_path && ::File.exist?(new_resource.public_key_path)
        resource.public_key_path new_resource.public_key_path
      end
      resource.size pkey.n.num_bytes * 8
      #resource.pass_phrase
      #resource.cipher?  Not sure how to get this from pem file
      resource.type case pkey.class
                    when OpenSSL::PKey::RSA
                      :rsa
                    when OpenSSL::PKey::DSA
                      :dsa
                    end 
      # TODO if user stores a der inside a pem file, we won't know it!  Not sure how to find out, either.
      resource.file_type new_file_type
      @current_resource = resource
    end
  else
    not_found_resource = Chef::Resource::CheffishPrivateKey.new(new_resource.path)
    not_found_resource.action :delete
    @current_resource = not_found_resource
  end
end
