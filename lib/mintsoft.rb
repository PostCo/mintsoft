# frozen_string_literal: true

require_relative "mintsoft/version"
require_relative "mintsoft/errors"
require_relative "mintsoft/base"
require_relative "mintsoft/auth_client"
require_relative "mintsoft/client"
require_relative "mintsoft/resources/base_resource"
require_relative "mintsoft/resources/orders"
require_relative "mintsoft/resources/returns"
require_relative "mintsoft/objects/order"
require_relative "mintsoft/objects/return"
require_relative "mintsoft/objects/return_reason"

module Mintsoft
  # Main entry point for the Mintsoft API wrapper
end
