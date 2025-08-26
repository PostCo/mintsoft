# frozen_string_literal: true

require "spec_helper"

RSpec.describe Mintsoft::AuthClient do
  let(:auth_client) { described_class.new }

  describe "#initialize" do
    it "sets default base URL" do
      expect(auth_client.base_url).to eq("https://api.mintsoft.com")
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
      it "returns AuthResponse with token" do
        stub_request(:post, "https://api.mintsoft.com/api/auth")
          .with(body: {username: "user", password: "pass"}.to_json)
          .to_return(
            status: 200,
            body: {token: "abc123", expires_in: 3600}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        response = auth_resource.authenticate("user", "pass")

        expect(response).to be_a(Mintsoft::AuthClient::AuthResponse)
        expect(response.token).to eq("abc123")
        expect(response.expires_in).to eq(3600)
      end
    end

    context "with invalid credentials" do
      it "raises AuthenticationError" do
        stub_request(:post, "https://api.mintsoft.com/api/auth")
          .to_return(status: 401, body: {error: "Invalid credentials"}.to_json)

        expect {
          auth_resource.authenticate("user", "wrongpass")
        }.to raise_error(Mintsoft::AuthenticationError, "Invalid credentials")
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

  describe "AuthResponse" do
    let(:response_data) { {"token" => "abc123", "expires_in" => 3600} }
    let(:auth_response) { Mintsoft::AuthClient::AuthResponse.new(response_data) }

    describe "#token" do
      it "returns token from response" do
        expect(auth_response.token).to eq("abc123")
      end
    end

    describe "#expires_at" do
      it "calculates expiry time from expires_in" do
        expect(auth_response.expires_at).to be_within(1).of(Time.now + 3600)
      end

      it "returns nil if no expires_in" do
        response = Mintsoft::AuthClient::AuthResponse.new({"token" => "abc123"})
        expect(response.expires_at).to be_nil
      end
    end

    describe "#expired?" do
      it "returns false for non-expired token" do
        expect(auth_response.expired?).to be false
      end

      it "returns true for expired token" do
        expired_response = Mintsoft::AuthClient::AuthResponse.new({
          "token" => "abc123",
          "expires_in" => -10
        })
        expect(expired_response.expired?).to be true
      end
    end
  end
end