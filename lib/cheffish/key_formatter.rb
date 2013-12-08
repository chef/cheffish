require 'openssl'
require 'net/ssh'
require 'etc'
require 'socket'

module Cheffish
  class KeyFormatter
    # Returns nil or key, format
    def self.decode(str, pass_phrase=nil, filename='')
      key_format = {}
      key_format[:format] = format_of(str)

      case key_format[:format]
      when :openssh
        key = decode_openssh_key(str, filename)
      else
        begin
          key = OpenSSL::PKey.read(str) { pass_phrase }
        rescue
          return nil
        end
      end

      key_format[:type] = type_of(key)
      key_format[:size] = size_of(key)
      key_format[:pass_phrase] = pass_phrase if pass_phrase
      # TODO cipher, exponent

      [key, key_format]
    end

    def self.encode(key, key_format)
      format = key_format[:format] || :pem
      case format
      when :openssh
        encode_openssh_key(key)
      when :pem
        if key_format[:pass_phrase]
          cipher = key_format[:cipher] || 'DES-EDE3-CBC'
          key.to_pem(OpenSSL::Cipher.new(cipher), key_format[:pass_phrase])
        else
          key.to_pem
        end
      when :der
        key.to_der
      else
        raise "Unrecognized key format #{format}"
      end
    end

    private

    def self.encode_openssh_key(key)
      # TODO there really isn't a method somewhere in net/ssh or openssl that does this??
      type = key.ssh_type
      data = [ key.to_blob ].pack('m0')
      "#{type} #{data} #{Etc.getlogin}@#{Socket.gethostname}"
    end

    def self.decode_openssh_key(str, filename='')
      Net::SSH::KeyFactory.load_data_public_key(str, filename)
    end

    def self.format_of(key_contents)
      if key_contents.start_with?('-----BEGIN ')
        :pem
      elsif key_contents.start_with?('ssh-rsa ') || key_contents.start_with?('ssh-dss ')
        :openssh
      else
        :der
      end
    end

    def self.type_of(key)
      case key.class
      when OpenSSL::PKey::RSA
        :rsa
      when OpenSSL::PKey::DSA
        :dsa
      end
    end

    def self.size_of(key)
      # TODO DSA -- this is RSA only
      key.n.num_bytes * 8
    end
  end
end
