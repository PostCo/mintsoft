# frozen_string_literal: true

module Mintsoft
  module Resources
    class Orders < BaseResource
      def search(order_number)
        validate_order_number!(order_number)

        response = get_request("/api/Order/Search", params: {"OrderNumber" => order_number})

        if response.success?
          parse_orders(response.body)
        else
          case response.status
          when 404
            [] # Return empty array for not found
          else
            handle_error(response)
          end
        end
      end

      private

      def validate_order_number!(order_number)
        raise ValidationError, "Order number required" if order_number.nil? || order_number.empty?
      end

      def parse_orders(data)
        return [] unless data.is_a?(Array)

        data.map { |order_data| Objects::Order.new(order_data) }
      end
    end
  end
end