require 'openssl' unless defined?(OpenSSL)
require 'net/ssh' unless defined?(Net::SSH)
require 'etc' unless defined?(Etc)
require 'socket' unless defined?(Socket)
require 'digest/md5' unless defined?(Digest::MD5)
require 'base64' unless defined?(Base64)

module Cheffish
  class KeyFormatter
    # Returns nil or key, format
    def self.decode(str, pass_phrase = nil, filename = '')
      key_format = {}
      key_format[:format] = format_of(str)

      case key_format[:format]
      when :openssh
        key = decode_openssh_key(str, filename)
      else
        begin
          key = OpenSSL::PKey.read(str) { pass_phrase }
        rescue
          return
        end
      end

      key_format[:type] = type_of(key) if type_of(key)
      key_format[:size] = size_of(key) if size_of(key)
      key_format[:pass_phrase] = pass_phrase if pass_phrase
      # TODO: cipher, exponent

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
      when :fingerprint, :pkcs1md5fingerprint
        hexes = Digest::MD5.hexdigest(key.to_der)
        # Put : between every pair of hexes
        hexes.scan(/../).join(':')
      when :rfc4716md5fingerprint
        _type, base64_data, _etc = encode_openssh_key(key).split
        data = Base64.decode64(base64_data)
        hexes = Digest::MD5.hexdigest(data)
        hexes.scan(/../).join(':')
      when :pkcs8sha1fingerprint
        raise 'PKCS8 SHA1 not supported by Ruby 2.0 and later'
      else
        raise "Unrecognized key format #{format}"
      end
    end

    def self.encode_openssh_key(key)
      # TODO: there really isn't a method somewhere in net/ssh or openssl that does this??
      type = key.ssh_type
      data = [ key.to_blob ].pack('m0')
      "#{type} #{data} #{Etc.getlogin}@#{Socket.gethostname}"
    end

    def self.decode_openssh_key(str, filename = '')
      Net::SSH::KeyFactory.load_data_public_key(str, filename)
    end

    def self.format_of(key_contents)
      if key_contents.start_with?('-----BEGIN ')
        :pem
      elsif key_contents.start_with?('ssh-rsa ', 'ssh-dss ')
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
      case key.class
      when OpenSSL::PKey::RSA
        key.n.num_bytes * 8
      end
    end
  end
end
