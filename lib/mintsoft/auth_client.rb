# frozen_string_literal: true

require "faraday"
require "faraday/net_http"

module Mintsoft
  class AuthClient
    BASE_URL = "https://api.mintsoft.co.uk"

    attr_reader :base_url, :conn_opts

    def initialize(base_url: BASE_URL, conn_opts: {})
      @base_url = base_url
      @conn_opts = conn_opts
    end

    def connection
      @connection ||= Faraday.new do |conn|
        conn.url_prefix = @base_url
        conn.options.merge!(@conn_opts)
        conn.request :json

        conn.adapter Faraday.default_adapter
      end
    end

    def auth
      @auth ||= AuthResource.new(self)
    end

    private

    class AuthResource
      def initialize(client)
        @client = client
      end

      def authenticate(username, password)
        validate_credentials!(username, password)

        response = @client.connection.post("/api/auth") do |req|
          req.body = {
            username: username,
            password: password
          }
        end

        if response.success?
          # the response body is like "\"xxxx-xx-xxxx\""
          if response.body.start_with?('"') && response.body.end_with?('"')
            response.body.gsub(/^["']|["']$/, "")
          else
            response.body
          end
        else
          handle_error_response(response)
        end
      end

      private

      def validate_credentials!(username, password)
        raise ValidationError, "Username required" if username.nil? || username.empty?
        raise ValidationError, "Password required" if password.nil? || password.empty?
      end

      def handle_error_response(response)
        case response.status
        when 401
          raise AuthenticationError, "Invalid credentials"
        when 400
          raise ValidationError, "Invalid request: #{extract_error_message(response.body)}"
        else
          raise APIError, "Authentication failed: #{response.status} - #{extract_error_message(response.body)}"
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
