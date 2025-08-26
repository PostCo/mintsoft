# frozen_string_literal: true

require "active_support"
require "active_support/core_ext/string"
require "ostruct"

module Mintsoft
  class Base < OpenStruct
    attr_reader :original_response

    def initialize(attributes)
      @original_response = deep_freeze_object(attributes)
      super to_ostruct(attributes)
    end

    def to_ostruct(obj)
      if obj.is_a?(Hash)
        OpenStruct.new(obj.transform_keys { |key| key.to_s.underscore }.transform_values { |val| to_ostruct(val) })
      elsif obj.is_a?(Array)
        obj.map { |o| to_ostruct(o) }
      else # Assumed to be a primitive value
        obj
      end
    end

    # Convert back to hash without table key, including nested structures
    def to_hash
      ostruct_to_hash(self)
    end

    private

    def deep_freeze_object(obj)
      case obj
      when Hash
        obj.transform_values { |value| deep_freeze_object(value) }.freeze
      when Array
        obj.map { |item| deep_freeze_object(item) }.freeze
      else
        obj.respond_to?(:freeze) ? obj.freeze : obj
      end
    end

    def ostruct_to_hash(object)
      case object
      when OpenStruct
        hash = object.to_h.reject { |k, _| k == :table }
        hash.transform_keys(&:to_s).transform_values { |value| ostruct_to_hash(value) }
      when Array
        object.map { |item| ostruct_to_hash(item) }
      when Hash
        object.transform_keys(&:to_s).transform_values { |value| ostruct_to_hash(value) }
      else
        object
      end
    end
  end
end