require 'cheffish/merged_config'

describe "merged_config" do

  let(:config) do
  	Cheffish::MergedConfig.new({:test=>'val'})
  end

  it "returns value in config" do
    expect(config.test).to eq('val')
  end

  it "raises a NoMethodError if calling an unknown method with arguments" do
    expect{config.merge({:some => 'hash'})}.to raise_error(NoMethodError)
  end

  it "has an informative string representation" do
  	expect("#{config}").to eq("{:test=>\"val\"}")
  end
end