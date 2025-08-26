# frozen_string_literal: true

module Mintsoft
  module Resources
    class BaseResource
      def initialize(client)
        @client = client
      end

      protected

      def get_request(url, params: {})
        @client.connection.get(url) do |req|
          req.params.merge!(params) unless params.empty?
        end
      end

      def post_request(url, body: {})
        @client.connection.post(url) do |req|
          req.body = body unless body.empty?
        end
      end

      def handle_response(response)
        if response.success?
          response.body
        else
          handle_error(response)
        end
      end

      def handle_error(response)
        case response.status
        when 401
          raise AuthenticationError, "Invalid or expired token"
        when 400
          raise ValidationError, "Invalid request data: #{extract_error_message(response.body)}"
        when 404
          raise NotFoundError, "Resource not found"
        else
          raise APIError, "API error: #{response.status} - #{extract_error_message(response.body)}"
        end
      end

      def extract_error_message(body)
        return body if body.is_a?(String)
        return body["error"] || body["message"] || body.to_s if body.is_a?(Hash)

        "Unknown error"
      end
    end
  end
end