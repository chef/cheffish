require "cheffish/merged_config"

describe "merged_config" do

  let(:config) do
    Cheffish::MergedConfig.new({ :test => "val" })
  end

  let(:collision) do
    c1 = { :test1 => "c1.1", "test2" => "c1.2" }
    c2 = { "test1" => "c2.1", "test3" => "c2.3" }
    Cheffish::MergedConfig.new(c1, c2)
  end

  let(:config_mismatch) do
    c1 = { :test => { :test => "val" } }
    c2 = { :test => [2, 3, 4] }
    Cheffish::MergedConfig.new(c1, c2)
  end

  let(:config_hashes) do
    c1 = { :test => { :test => "val" } }
    c2 = { :test => { :test2 => "val2" } }
    Cheffish::MergedConfig.new(c1, c2)
  end

  it "returns value in config" do
    expect(config.test).to eq("val")
  end

  it "raises a NoMethodError if calling an unknown method with arguments" do
    expect { config.merge({ :some => "hash" }) }.to raise_error(NoMethodError)
  end

  it "has an informative string representation" do
    expect("#{config}").to eq("{\"test\"=>\"val\"}")
  end

  it "has indifferent str/sym access" do
    expect(config["test"]).to eq("val")
  end

  it "respects precedence between the different configs" do
    expect(collision["test1"]).to eq("c1.1")
    expect(collision[:test1]).to eq("c1.1")
  end

  it "merges the configs" do
    expect(collision[:test2]).to eq("c1.2")
    expect(collision[:test3]).to eq("c2.3")
  end

  it "handle merged value type mismatch" do
    expect(config_mismatch[:test]).to eq("test" => "val")
  end

  it "merges values when they're hashes" do
    expect(config_hashes[:test].keys).to eq(%w{test test2})
  end
end
