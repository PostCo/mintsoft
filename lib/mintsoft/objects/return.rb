# frozen_string_literal: true

module Mintsoft
  module Objects
    class Return < Base
      # Access nested items as OpenStruct objects
      def items
        return_items || items_array || []
      end

      def items_count
        items.length
      end

      # Access item properties through OpenStruct
      def item_quantities
        return 0 unless items.respond_to?(:map)
        items.map { |item| item.respond_to?(:quantity) ? item.quantity.to_i : 0 }.sum
      end

      # Convenient access to return identifier
      def return_id
        respond_to?(:id) ? id : super
      end

      # Check if return has any items
      def has_items?
        items.is_a?(Array) && items.any?
      end
    end
  end
end
