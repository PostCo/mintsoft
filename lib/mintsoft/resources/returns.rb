# frozen_string_literal: true

require "json"

module Mintsoft
  module Resources
    class Returns < BaseResource
      def reasons
        response = get_request("/api/Return/Reasons")

        if response.success?
          parse_reasons(response.body)
        else
          handle_error(response)
        end
      end

      def create(order_id)
        validate_order_id!(order_id)

        response = post_request("/api/Return/CreateReturn/#{order_id}")

        if response.success?
          # Pass entire response to Return object, let Base class handle transformation
          enhanced_response = response.body.merge({
            "order_id" => order_id
          })
          Objects::Return.new(enhanced_response)
        else
          handle_error(response)
        end
      end

      def add_item(return_id, item_attributes)
        validate_return_id!(return_id)
        validate_item_attributes!(item_attributes)

        payload = format_item_payload(item_attributes)
        response = post_request("/api/Return/#{return_id}/AddItem", body: payload)

        if response.success?
          # Ensure response.body is a Hash, parse if it's a String
          response_data = response.body.is_a?(Hash) ? response.body : JSON.parse(response.body)
          
          # Return the response as a Return object with original response preserved
          enhanced_response = response_data.merge({
            "return_id" => return_id,
            "item_attributes" => item_attributes
          })
          Objects::Return.new(enhanced_response)
        else
          handle_error(response)
        end
      end

      private

      def validate_order_id!(order_id)
        raise ValidationError, "Order ID required" unless order_id&.to_i&.positive?
      end

      def validate_return_id!(return_id)
        raise ValidationError, "Return ID required" unless return_id&.to_i&.positive?
      end

      def validate_item_attributes!(attrs)
        required = [:product_id, :quantity, :reason_id]
        required.each do |field|
          raise ValidationError, "#{field} required" unless attrs[field]
        end
        raise ValidationError, "Quantity must be positive" unless attrs[:quantity].to_i > 0
      end

      def parse_reasons(data)
        return [] unless data.is_a?(Array)

        data.map { |reason_data| Objects::ReturnReason.new(reason_data) }
      end

      def extract_return_id(toolkit_result)
        # Parse ToolkitResult to extract return ID - handles various response formats
        toolkit_result.dig("result", "return_id") ||
        toolkit_result.dig("data", "id") ||
        toolkit_result["id"]
      end

      def format_item_payload(attrs)
        {
          "ProductId" => attrs[:product_id],
          "Quantity" => attrs[:quantity],
          "ReasonId" => attrs[:reason_id],
          "UnitValue" => attrs[:unit_value],
          "Notes" => attrs[:notes]
        }.compact
      end
    end
  end
end