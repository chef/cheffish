require "cheffish"

describe "api version" do

  let(:server_api) do
    Cheffish.chef_server_api({ :chef_server_url => "my.chef.server" })
  end

  it "is pinned to 0" do
    expect(Cheffish::ServerAPI).to receive(:new).with("my.chef.server", { api_version: "0" })
    server_api
  end
end
