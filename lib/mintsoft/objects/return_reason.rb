# frozen_string_literal: true

module Mintsoft
  module Objects
    class ReturnReason < Base
      def active?
        active == true
      end
    end
  end
end