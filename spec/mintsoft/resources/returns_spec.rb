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

      stub_request(:get, "https://api.mintsoft.co.uk/api/Return/Reasons")
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
      it "returns Return object with original response data" do
        response_data = {"id" => 123, "result" => {"return_id" => 123}}

        stub_request(:post, "https://api.mintsoft.co.uk/api/Return/CreateReturn/456")
          .to_return(
            status: 200,
            body: response_data.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        result = returns_resource.create(456)

        expect(result).to be_a(Mintsoft::Objects::Return)
        expect(result.id).to eq(123)

        # Test original response is preserved
        expect(result.original_response["id"]).to eq(123)
        expect(result.original_response["result"]).to eq({"return_id" => 123})
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
      it "returns Return object with response data" do
        response_data = {
          "ID" => 789,
          "Success" => true,
          "SensitiveData" => "encrypted_data",
          "Message" => "Item added successfully",
          "WarningMessage" => "Stock level low",
          "AllocatedFromReplen" => true
        }

        stub_request(:post, "https://api.mintsoft.co.uk/api/Return/456/AddItem")
          .with(body: {
            "ProductId" => 123,
            "Quantity" => 2,
            "ReasonId" => 1,
            "UnitValue" => 25.00,
            "Notes" => "Damaged item"
          }.to_json)
          .to_return(status: 200, body: response_data.to_json, headers: {"Content-Type" => "application/json"})

        result = returns_resource.add_item(456, valid_item_attributes)

        expect(result).to be_a(Mintsoft::Objects::Return)
        # Test snake_case transformation
        expect(result.id).to eq(789)
        expect(result.success).to be true
        expect(result.sensitive_data).to eq("encrypted_data")
        expect(result.message).to eq("Item added successfully")
        expect(result.warning_message).to eq("Stock level low")
        expect(result.allocated_from_replen).to be true
        # return_id is not injected into the response anymore

        # Test original response is preserved with original casing
        expect(result.original_response["ID"]).to eq(789)
        expect(result.original_response["Success"]).to be true
        expect(result.original_response["SensitiveData"]).to eq("encrypted_data")
        expect(result.original_response["Message"]).to eq("Item added successfully")
        expect(result.original_response["WarningMessage"]).to eq("Stock level low")
        expect(result.original_response["AllocatedFromReplen"]).to be true
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

  describe "#retrieve" do
    context "with valid return ID" do
      it "returns Return object with response data" do
        response_data = {
          "ID" => 123,
          "OrderID" => 456,
          "Status" => "Pending",
          "CreatedDate" => "2024-01-15T10:30:00Z",
          "CustomerName" => "John Doe",
          "TotalValue" => 150.00
        }

        stub_request(:get, "https://api.mintsoft.co.uk/api/Return/123")
          .to_return(
            status: 200,
            body: response_data.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        result = returns_resource.retrieve(123)

        expect(result).to be_a(Mintsoft::Objects::Return)
        expect(result.id).to eq(123)
        expect(result.order_id).to eq(456)
        expect(result.status).to eq("Pending")
        expect(result.created_date).to eq("2024-01-15T10:30:00Z")
        expect(result.customer_name).to eq("John Doe")
        expect(result.total_value).to eq(150.00)

        # Test original response is preserved with original casing
        expect(result.original_response["ID"]).to eq(123)
        expect(result.original_response["OrderID"]).to eq(456)
        expect(result.original_response["Status"]).to eq("Pending")
        expect(result.original_response["CreatedDate"]).to eq("2024-01-15T10:30:00Z")
        expect(result.original_response["CustomerName"]).to eq("John Doe")
        expect(result.original_response["TotalValue"]).to eq(150.00)
      end
    end

    context "with invalid return ID" do
      it "raises ValidationError for invalid return ID" do
        expect {
          returns_resource.retrieve(0)
        }.to raise_error(Mintsoft::ValidationError, "Return ID required")

        expect {
          returns_resource.retrieve(nil)
        }.to raise_error(Mintsoft::ValidationError, "Return ID required")
      end
    end

    context "with non-existent return ID" do
      it "returns nil for 404 response" do
        stub_request(:get, "https://api.mintsoft.co.uk/api/Return/999")
          .to_return(
            status: 404,
            body: {"error" => "Return not found"}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        result = returns_resource.retrieve(999)
        expect(result).to be_nil
      end
    end

    context "with API error" do
      it "raises appropriate error for other status codes" do
        stub_request(:get, "https://api.mintsoft.co.uk/api/Return/123")
          .to_return(
            status: 500,
            body: {"error" => "Internal server error"}.to_json,
            headers: {"Content-Type" => "application/json"}
          )

        expect {
          returns_resource.retrieve(123)
        }.to raise_error(Mintsoft::APIError, /API error: 500/)
      end
    end
  end
end
