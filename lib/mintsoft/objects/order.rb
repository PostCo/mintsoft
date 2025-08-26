# frozen_string_literal: true

module Mintsoft
  module Objects
    class Order < Base
      # Convenient access to order identifier
      def order_id
        respond_to?(:id) ? id : super
      end

      # Convenient access to order reference/number
      def order_ref
        order_number || order_reference || ref || nil
      end

      # Check if order has associated items
      def has_items?
        respond_to?(:items) && items&.any?
      end

      # Get total item count
      def items_count
        return 0 unless has_items?
        items.is_a?(Array) ? items.length : 0
      end
    end
  end
end
