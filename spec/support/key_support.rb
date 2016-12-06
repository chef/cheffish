RSpec::Matchers.define :be_public_key_for do |private_key, pass_phrase|
  match do |public_key|
    if public_key.is_a?(String)
      public_key, public_key_format = Cheffish::KeyFormatter.decode(IO.read(File.expand_path(public_key)), pass_phrase, public_key)
    end
    if private_key.is_a?(String)
      private_key, private_key_format = Cheffish::KeyFormatter.decode(IO.read(File.expand_path(private_key)), pass_phrase, private_key)
    end

    encrypted = public_key.public_encrypt("hi there")
    expect(private_key.private_decrypt(encrypted)).to eq("hi there")
  end
end

RSpec::Matchers.define :match_private_key do |expected, pass_phrase|
  match do |actual|
    if expected.is_a?(String)
      expected, format = Cheffish::KeyFormatter.decode(IO.read(File.expand_path(expected)), pass_phrase, expected)
    end
    if actual.is_a?(String)
      actual, format = Cheffish::KeyFormatter.decode(IO.read(File.expand_path(actual)), pass_phrase, actual)
    end

    encrypted = actual.public_encrypt("hi there")
    expect(expected.private_decrypt(encrypted)).to eq("hi there")
    encrypted = expected.public_encrypt("hi there")
    expect(actual.private_decrypt(encrypted)).to eq("hi there")
  end
end
