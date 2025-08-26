# frozen_string_literal: true

require "spec_helper"

RSpec.describe "Complete Mintsoft workflow" do
  let(:username) { "test_user" }
  let(:password) { "test_pass" }
  let(:token) { "abc123token" }
  let(:order_number) { "ORD-2024-001" }

  describe "Token management and API operations" do
    it "completes the full workflow from authentication to return creation" do
      # Step 1: Authentication
      stub_request(:post, "https://api.mintsoft.co.uk/api/auth")
        .with(body: {username: username, password: password}.to_json)
        .to_return(
          status: 200,
          body: token,
          headers: {"Content-Type" => "application/json; charset=utf-8"}
        )

      auth_client = Mintsoft::AuthClient.new
      token_result = auth_client.auth.authenticate(username, password)

      expect(token_result).to eq(token)

      # Step 2: Initialize client with token
      client = Mintsoft::Client.new(token: token_result)

      # Step 3: Search for order
      order_data = [{
        "Id" => 123,
        "OrderNumber" => order_number,
        "CustomerID" => 456,
        "Status" => "Fulfilled"
      }]

      stub_request(:get, "https://api.mintsoft.co.uk/api/Order/Search")
        .with(query: {"OrderNumber" => order_number})
        .to_return(
          status: 200,
          body: order_data.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      orders = client.orders.search(order_number)
      order = orders.first

      expect(order).to be_a(Mintsoft::Objects::Order)
      expect(order.id).to eq(123)
      expect(order.order_number).to eq(order_number)

      # Step 4: Get return reasons
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

      reasons = client.returns.reasons
      damage_reason = reasons.find { |r| r.name.include?("Damaged") && r.active? }

      expect(reasons.size).to eq(2)
      expect(damage_reason).to be_a(Mintsoft::Objects::ReturnReason)
      expect(damage_reason.name).to eq("Damaged")

      # Step 5: Create return
      return_response_data = {"id" => 789, "result" => {"return_id" => 789}}

      stub_request(:post, "https://api.mintsoft.co.uk/api/Return/CreateReturn/#{order.id}")
        .to_return(
          status: 200,
          body: return_response_data.to_json,
          headers: {"Content-Type" => "application/json"}
        )

      return_obj = client.returns.create(order.id)

      expect(return_obj).to be_a(Mintsoft::Objects::Return)
      expect(return_obj.id).to eq(789)
      expect(return_obj.order_id).to eq(order.id)

      # Step 6: Add item to return
      stub_request(:post, "https://api.mintsoft.co.uk/api/Return/#{return_obj.id}/AddItem")
        .with(body: {
          "ProductId" => 123,
          "Quantity" => 2,
          "ReasonId" => damage_reason.id,
          "UnitValue" => 25.00,
          "Notes" => "Damaged in shipping"
        }.to_json)
        .to_return(status: 200, body: {success: true}.to_json, headers: {"Content-Type" => "application/json"})

      add_item_result = client.returns.add_item(return_obj.id, {
        product_id: 123,
        quantity: 2,
        reason_id: damage_reason.id,
        unit_value: 25.00,
        notes: "Damaged in shipping"
      })

      expect(add_item_result).to be_a(Mintsoft::Objects::Return)
      expect(add_item_result.success).to be true
    end
  end

  describe "Error handling in workflow" do
    it "handles authentication failure gracefully" do
      stub_request(:post, "https://api.mintsoft.co.uk/api/auth")
        .to_return(status: 401, body: {error: "Invalid credentials"}.to_json)

      auth_client = Mintsoft::AuthClient.new

      expect {
        auth_client.auth.authenticate("bad_user", "bad_pass")
      }.to raise_error(Mintsoft::AuthenticationError, "Invalid credentials")
    end

    it "handles expired token gracefully" do
      client = Mintsoft::Client.new(token: "expired_token")

      stub_request(:get, "https://api.mintsoft.co.uk/api/Order/Search")
        .with(query: {"OrderNumber" => order_number},
          headers: {"Authorization" => "Bearer expired_token"})
        .to_return(status: 401)

      expect {
        client.orders.search(order_number)
      }.to raise_error(Mintsoft::AuthenticationError, "Invalid or expired token")
    end

    it "handles order not found gracefully" do
      client = Mintsoft::Client.new(token: token)

      stub_request(:get, "https://api.mintsoft.co.uk/api/Order/Search")
        .with(query: {"OrderNumber" => "NOTFOUND"})
        .to_return(status: 404)

      result = client.orders.search("NOTFOUND")
      expect(result).to eq([])
    end
  end
end
