# frozen_string_literal: true

module Mintsoft
  class Error < StandardError; end
  class APIError < Error; end
  class AuthenticationError < APIError; end
  class NotFoundError < APIError; end
  class ValidationError < APIError; end
end