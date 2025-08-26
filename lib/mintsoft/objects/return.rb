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
        items.map(&:quantity).sum
      end

      # Convenience methods for common API response formats
      def return_id
        id || return_id
      end
    end
  end
end