# frozen_string_literal: true

require "spec_helper"

RSpec.describe Mintsoft::AuthClient do
  let(:auth_client) { described_class.new }

  describe "#initialize" do
    it "sets default base URL" do
      expect(auth_client.base_url).to eq("https://api.mintsoft.co.uk")
    end

    it "accepts custom base URL" do
      client = described_class.new(base_url: "https://custom.api.com")
      expect(client.base_url).to eq("https://custom.api.com")
    end
  end

  describe "#auth" do
    it "returns AuthResource instance" do
      expect(auth_client.auth).to be_a(Mintsoft::AuthClient::AuthResource)
    end
  end

  describe "AuthResource#authenticate" do
    let(:auth_resource) { auth_client.auth }

    context "with valid credentials" do
      it "returns response body directly" do
        stub_request(:post, "https://api.mintsoft.co.uk/api/auth")
          .with(body: {username: "user", password: "pass"}.to_json)
          .to_return(
            status: 200,
            body: "abc123",
            headers: {"Content-Type" => "application/json; charset=utf-8"}
          )

        response_body = auth_resource.authenticate("user", "pass")

        expect(response_body).to eq("abc123")
        expect(response_body).to be_a(String)
      end
    end

    context "with invalid credentials" do
      it "raises AuthenticationError" do
        stub_request(:post, "https://api.mintsoft.co.uk/api/auth")
          .to_return(status: 401, body: {error: "Invalid credentials"}.to_json)

        expect {
          auth_resource.authenticate("user", "wrongpass")
        }.to raise_error(Mintsoft::AuthClient::AuthenticationError, "Invalid credentials")
      end
    end

    context "with missing credentials" do
      it "raises ValidationError for missing username" do
        expect {
          auth_resource.authenticate("", "pass")
        }.to raise_error(Mintsoft::ValidationError, "Username required")
      end

      it "raises ValidationError for missing password" do
        expect {
          auth_resource.authenticate("user", "")
        }.to raise_error(Mintsoft::ValidationError, "Password required")
      end
    end
  end
end
