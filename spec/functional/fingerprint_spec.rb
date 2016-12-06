require "cheffish/key_formatter"
require "support/key_support"

describe "Cheffish fingerprint key formatter" do

  # Sample key: 0x9a6fa4c43b328c3d04c1fbc0498539218b6728e41cd35f6d27d491ef705f0b2083dc1ac977da19f54ba82b044773f20667e9627c543abb3b41b6eb9e4318ca3c68f487bbd0f1c9eea9a3101b7d1d180983c5440ac4183e78e9e256fa687d8aac63b21617a4b02b35bf5e307a3b76961a16cd8493e923536b34cc2b2da8d45220d57ef2243b081b555b84f1da0ade0e896c2aa96911b41430b59eaf75dbffb7eaa7c5b3a686f2d47a24e3b7f1acb0844f84a2fedc63660ae366b800cd9448093d6b1d96503ebb7807b48257e16c3d8a7c9a8cc5dd63116aa673bd9e09754de09358486e743e34c6a3642eeb64b2208efc96df39151572557a75638bd059c21a55 = 0xd6e92677d4e1d2aa6d14f87b5f49ee6916c6b92411536254fae4a21e82eebb0a40600247c701c1c938b21ca9f25b7b330c35fded57b4de3a951e83329a80bdbf2ba138fe2f190bffce43967b5fa93b179367bcd15cb1db7f9e3ab62caca95dc9489b62bc0a10b53841b932455a43409f96eed90dc80abc8cce5593ead8f0a26d * 0xb7f68cd427045788d5e315375f71d3a416784ec2597776a60ed77c821294d9bd66e96658bdcb43072cee0c849d297bd9f94991738f1a0df313ceb51b093a9372f12a61987f40e7a03d773911deb270916a574962ae8ff4f2d8bfcedee1c885e9c3e54212471636a6330b05b78c3a7ddf96b013be389a08ab7971db2f68fb2689

  sample_private_key = <<EOF
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAmm+kxDsyjD0EwfvASYU5IYtnKOQc019tJ9SR73BfCyCD3BrJd9oZ9UuoKwRH
c/IGZ+lifFQ6uztBtuueQxjKPGj0h7vQ8cnuqaMQG30dGAmDxUQKxBg+eOniVvpofYqsY7IWF6Sw
KzW/XjB6O3aWGhbNhJPpI1NrNMwrLajUUiDVfvIkOwgbVVuE8doK3g6JbCqpaRG0FDC1nq912/+3
6qfFs6aG8tR6JOO38aywhE+Eov7cY2YK42a4AM2USAk9ax2WUD67eAe0glfhbD2KfJqMxd1jEWqm
c72eCXVN4JNYSG50PjTGo2Qu62SyII78lt85FRVyVXp1Y4vQWcIaVQIDAQABAoIBABY+JC37FLGs
DCZgOvab0HmrWUVDbX9oDBGjhQ1GUvoISdWGqiOv7vMsXWEssZnabt/CdmPPwdG7nCBbWSTyyhXf
S/DMtTBN1CjsimJbJ7iRjj/4J9DMaRsDHI1IbYo/UcreGF55YsImcJSBSOmNj9rcE+eXYgmrdxJY
oZNm8IWPaZ1/8KdPHSq6/HfTzRxXhcGOMGnf3lGfzkzIbV9Ee88Lv9sSV3bYrOsWMNabOe2TeTpC
UTfFkC++0RkFjEDINSCnoCi+ybzHLUDnurANCwnRWLTVEAeffwNVmiDfgimuqFtzCInW5/5bOTPz
rBmcC6QAFbyk2WKAlY8Zd4SBYqECgYEA1ukmd9Th0qptFPh7X0nuaRbGuSQRU2JU+uSiHoLuuwpA
YAJHxwHByTiyHKnyW3szDDX97Ve03jqVHoMymoC9vyuhOP4vGQv/zkOWe1+pOxeTZ7zRXLHbf546
tiysqV3JSJtivAoQtThBuTJFWkNAn5bu2Q3ICryMzlWT6tjwom0CgYEAt/aM1CcEV4jV4xU3X3HT
pBZ4TsJZd3amDtd8ghKU2b1m6WZYvctDByzuDISdKXvZ+UmRc48aDfMTzrUbCTqTcvEqYZh/QOeg
PXc5Ed6ycJFqV0liro/08ti/zt7hyIXpw+VCEkcWNqYzCwW3jDp935awE744mgireXHbL2j7JokC
gYAOHErRTWHyYgw9dz8qd4E21y7/EvYsQmWP/5kBZdlk4HxvkVbDI0NlAdr39NSb2w/z+kuM3Nhc
Sv5lfXnCGTfcKHIyesX+4AHQujFUMmi7H4YnJoecjXT7ARmbwn0ntae0o7cs34BPVb1C+qEBFy9U
CyXtjHEY+15HYekPX2UVVQKBgBT8Nwxsdv5VSbDh1rM4lN//ADJb0UDjdAX1ZuqfnANKq9asKitc
aIUFBxK+ff8hdbgOQF1iUaKNvBC0cCUZXYCbKi5/6uRIh+r7ErOLJ+fXbr4OTQeEvHiHaTn8Ct2J
CSWjnWngWhRZ2TDEsi947Kr40ZUu+d34ZzcvWcWKwDuhAoGBAJzCRoGOu6YGy+rBPxaIg0vB+Grx
rxs0NeNqGdrzmyAPN35OHXYclPwfp+DbtbJHgGMRc/9VFPqW9PeTKjIByeEsXyrcdreR35AR/fwR
AUcSSKTvw+PobCpXhdkiw4TgJhFNuZnoC63FOjNqA5mu1ICZYBb4ZVlgUAgSmDQxSIgK
-----END RSA PRIVATE KEY-----
EOF
  sample_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCab6TEOzKMPQTB+8BJhTkhi2co5BzTX20n1JHvcF8LIIPcGsl32hn1S6grBEdz8gZn6WJ8VDq7O0G2655DGMo8aPSHu9Dxye6poxAbfR0YCYPFRArEGD546eJW+mh9iqxjshYXpLArNb9eMHo7dpYaFs2Ek+kjU2s0zCstqNRSINV+8iQ7CBtVW4Tx2greDolsKqlpEbQUMLWer3Xb/7fqp8Wzpoby1Hok47fxrLCET4Si/txjZgrjZrgAzZRICT1rHZZQPrt4B7SCV+FsPYp8mozF3WMRaqZzvZ4JdU3gk1hIbnQ+NMajZC7rZLIgjvyW3zkVFXJVenVji9BZwhpV"

  def key_to_format(key, format)
    keyobj, f = Cheffish::KeyFormatter.decode(key)
    Cheffish::KeyFormatter.encode(keyobj, { :format => format })
  end

  context "when computing key fingperprints" do

    it "computes the PKCS#8 SHA1 private key fingerprint correctly", :pending => (RUBY_VERSION.to_f >= 2.0) do
      expect(key_to_format(sample_private_key, :pkcs8sha1fingerprint)).to eq(
        "88:7e:3a:bd:26:9f:b5:c5:d8:ae:52:f9:df:0b:64:a4:5c:17:0a:87")
    end

    it "computes the PKCS#1 MD5 public key fingerprint correctly" do
      expect(key_to_format(sample_public_key, :pkcs1md5fingerprint)).to eq(
        "1f:e8:da:c1:16:c3:72:7d:90:e2:b7:64:c4:b4:55:20")
    end

    it "computes the RFC4716 MD5 public key fingerprint correctly" do
      expect(key_to_format(sample_public_key, :rfc4716md5fingerprint)).to eq(
        "b0:13:4f:da:cf:8c:dc:a7:4a:1f:d2:3a:51:92:cf:6b")
    end

    it "defaults to the PKCS#1 MD5 public key fingerprint" do
      expect(key_to_format(sample_public_key, :fingerprint)).to eq(
        key_to_format(sample_public_key, :pkcs1md5fingerprint))
    end

  end

end
