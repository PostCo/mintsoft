# frozen_string_literal: true

require "spec_helper"

RSpec.describe Mintsoft::Client do
  let(:token) { "test_token_123" }
  let(:client) { described_class.new(token: token) }

  describe "#initialize" do
    it "requires token" do
      expect { described_class.new }.to raise_error(ArgumentError, /missing keyword.*token/)
    end

    it "sets token" do
      expect(client.token).to eq(token)
    end

    it "sets default base URL" do
      expect(client.base_url).to eq("https://api.mintsoft.co.uk")
    end

    it "accepts custom base URL" do
      custom_client = described_class.new(token: token, base_url: "https://custom.api.com")
      expect(custom_client.base_url).to eq("https://custom.api.com")
    end
  end

  describe "#connection" do
    it "creates Faraday connection with bearer token" do
      connection = client.connection
      expect(connection).to be_a(Faraday::Connection)
      expect(connection.url_prefix.to_s).to eq("https://api.mintsoft.co.uk/")
    end
  end

  describe "#orders" do
    it "returns Orders resource instance" do
      expect(client.orders).to be_a(Mintsoft::Resources::Orders)
    end

    it "memoizes the resource" do
      expect(client.orders).to be(client.orders)
    end
  end

  describe "#returns" do
    it "returns Returns resource instance" do
      expect(client.returns).to be_a(Mintsoft::Resources::Returns)
    end

    it "memoizes the resource" do
      expect(client.returns).to be(client.returns)
    end
  end
end
