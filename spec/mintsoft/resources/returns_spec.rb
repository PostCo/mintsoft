# frozen_string_literal: true

require "spec_helper"

RSpec.describe Mintsoft::Resources::Returns do
  let(:token) { "test_token" }
  let(:client) { Mintsoft::Client.new(token: token) }
  let(:returns_resource) { described_class.new(client) }

  describe "#reasons" do
    it "returns array of ReturnReason objects" do
      reasons_data = [
        {"Id" => 1, "Name" => "Damaged", "Description" => "Item damaged", "Active" => true},
        {"Id" => 2, "Name" => "Wrong Size", "Description" => "Wrong size", "Active" => true}
      ]

      stub_request(:get, "https://api.mintsoft.com/api/Return/Reasons")
        .to_return(
          status: 200,
          body: reasons_data.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      result = returns_resource.reasons

      expect(result).to be_an(Array)
      expect(result.size).to eq(2)
      expect(result.first).to be_a(Mintsoft::Objects::ReturnReason)
      expect(result.first.name).to eq("Damaged")
      expect(result.first.active?).to be true
    end
  end

  describe "#create" do
    context "with valid order ID" do
      it "returns Return object" do
        response_data = {"id" => 123, "result" => {"return_id" => 123}}

        stub_request(:post, "https://api.mintsoft.com/api/Return/CreateReturn/456")
          .to_return(
            status: 200,
            body: response_data.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        result = returns_resource.create(456)

        expect(result).to be_a(Mintsoft::Objects::Return)
        expect(result.id).to eq(123)
        expect(result.order_id).to eq(456)
        expect(result.status).to eq("pending")
      end
    end

    context "with invalid order ID" do
      it "raises ValidationError for invalid order ID" do
        expect {
          returns_resource.create(0)
        }.to raise_error(Mintsoft::ValidationError, "Order ID required")

        expect {
          returns_resource.create(nil)
        }.to raise_error(Mintsoft::ValidationError, "Order ID required")
      end
    end
  end

  describe "#add_item" do
    let(:valid_item_attributes) do
      {
        product_id: 123,
        quantity: 2,
        reason_id: 1,
        unit_value: 25.00,
        notes: "Damaged item"
      }
    end

    context "with valid parameters" do
      it "returns true on success" do
        stub_request(:post, "https://api.mintsoft.com/api/Return/456/AddItem")
          .with(body: {
            "ProductId" => 123,
            "Quantity" => 2,
            "ReasonId" => 1,
            "UnitValue" => 25.00,
            "Notes" => "Damaged item"
          }.to_json)
          .to_return(status: 200, body: {success: true}.to_json)

        result = returns_resource.add_item(456, valid_item_attributes)
        expect(result).to be true
      end
    end

    context "with invalid parameters" do
      it "raises ValidationError for invalid return ID" do
        expect {
          returns_resource.add_item(0, valid_item_attributes)
        }.to raise_error(Mintsoft::ValidationError, "Return ID required")
      end

      it "raises ValidationError for missing required fields" do
        invalid_attributes = valid_item_attributes.except(:product_id)

        expect {
          returns_resource.add_item(456, invalid_attributes)
        }.to raise_error(Mintsoft::ValidationError, "product_id required")
      end

      it "raises ValidationError for invalid quantity" do
        invalid_attributes = valid_item_attributes.merge(quantity: 0)

        expect {
          returns_resource.add_item(456, invalid_attributes)
        }.to raise_error(Mintsoft::ValidationError, "Quantity must be positive")
      end
    end
  end
end