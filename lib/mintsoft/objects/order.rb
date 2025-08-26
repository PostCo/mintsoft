# frozen_string_literal: true

module Mintsoft
  module Objects
    class Order < Base
      # Convenience methods for common API response formats
      def order_id
        id || order_id
      end

      def order_ref
        order_number || order_reference || ref
      end
    end
  end
end