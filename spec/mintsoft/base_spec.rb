# frozen_string_literal: true

require "spec_helper"

RSpec.describe Mintsoft::Base do
  describe "#initialize" do
    it "converts hash attributes to OpenStruct with underscore keys" do
      data = {
        "OrderNumber" => "ORD-123",
        "CustomerID" => 456,
        "nested_object" => {
          "ProductID" => 789
        }
      }

      obj = described_class.new(data)

      expect(obj.order_number).to eq("ORD-123")
      expect(obj.customer_id).to eq(456)
      expect(obj.nested_object.product_id).to eq(789)
    end

    it "handles arrays of objects" do
      data = {
        "items" => [
          {"ProductID" => 123, "Quantity" => 2},
          {"ProductID" => 456, "Quantity" => 1}
        ]
      }

      obj = described_class.new(data)

      expect(obj.items).to be_an(Array)
      expect(obj.items.first.product_id).to eq(123)
      expect(obj.items.first.quantity).to eq(2)
    end
  end

  describe "#to_hash" do
    it "converts back to hash without table key" do
      data = {"OrderNumber" => "ORD-123", "CustomerID" => 456}
      obj = described_class.new(data)

      hash = obj.to_hash
      expect(hash).to eq({"order_number" => "ORD-123", "customer_id" => 456})
      expect(hash.keys).not_to include(:table)
    end
  end
end