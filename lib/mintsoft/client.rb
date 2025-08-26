# frozen_string_literal: true

require "faraday"
require "faraday/net_http"

module Mintsoft
  class Client
    BASE_URL = "https://api.mintsoft.com"

    attr_reader :token, :base_url, :conn_opts

    def initialize(token:, base_url: BASE_URL, conn_opts: {})
      @token = token
      @base_url = base_url
      @conn_opts = conn_opts
    end

    def connection
      @connection ||= Faraday.new do |conn|
        conn.url_prefix = @base_url
        conn.options.merge!(@conn_opts)
        conn.request :authorization, :Bearer, @token
        conn.request :json
        conn.response :json, content_type: "application/json"
        conn.adapter Faraday.default_adapter
      end
    end

    def orders
      @orders ||= Resources::Orders.new(self)
    end

    def returns
      @returns ||= Resources::Returns.new(self)
    end
  end
end