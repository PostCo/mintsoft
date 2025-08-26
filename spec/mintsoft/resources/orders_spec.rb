# frozen_string_literal: true

require "spec_helper"

RSpec.describe Mintsoft::Resources::Orders do
  let(:token) { "test_token" }
  let(:client) { Mintsoft::Client.new(token: token) }
  let(:orders_resource) { described_class.new(client) }

  describe "#search" do
    context "with valid order number" do
      it "returns array of Order objects" do
        order_data = [
          {"Id" => 1, "OrderNumber" => "ORD-123", "CustomerID" => 456},
          {"Id" => 2, "OrderNumber" => "ORD-124", "CustomerID" => 789}
        ]

        stub_request(:get, "https://api.mintsoft.com/api/Order/Search")
          .with(query: {"OrderNumber" => "ORD-123"})
          .to_return(
            status: 200,
            body: order_data.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        result = orders_resource.search("ORD-123")

        expect(result).to be_an(Array)
        expect(result.size).to eq(2)
        expect(result.first).to be_a(Mintsoft::Objects::Order)
        expect(result.first.id).to eq(1)
        expect(result.first.order_number).to eq("ORD-123")
      end
    end

    context "when order not found" do
      it "returns empty array for 404 response" do
        stub_request(:get, "https://api.mintsoft.com/api/Order/Search")
          .with(query: {"OrderNumber" => "NOTFOUND"})
          .to_return(status: 404)

        result = orders_resource.search("NOTFOUND")
        expect(result).to eq([])
      end
    end

    context "with invalid order number" do
      it "raises ValidationError for empty order number" do
        expect {
          orders_resource.search("")
        }.to raise_error(Mintsoft::ValidationError, "Order number required")
      end

      it "raises ValidationError for nil order number" do
        expect {
          orders_resource.search(nil)
        }.to raise_error(Mintsoft::ValidationError, "Order number required")
      end
    end

    context "with authentication error" do
      it "raises AuthenticationError for 401 response" do
        stub_request(:get, "https://api.mintsoft.com/api/Order/Search")
          .with(query: {"OrderNumber" => "ORD-123"},
                headers: {"Authorization" => "Bearer test_token"})
          .to_return(status: 401)

        expect {
          orders_resource.search("ORD-123")
        }.to raise_error(Mintsoft::AuthenticationError, "Invalid or expired token")
      end
    end
  end
end