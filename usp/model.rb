require './utils/hash_utils'
require 'active_support/core_ext/numeric/time'

module USP
  class Model
    attr_reader :model

    def initialize(model)
      @model ||= if model.is_a? Hash
                   model.deep_symbolize_keys
                 else
                   {model: model.symbolize_keys}
                 end
      created
    end

    def created
      @created ||= Time.now
    end

    def valid?
      20.hours.ago < created
    end

    def method_missing(name, *args)
      n = (name.to_s.gsub /\=/, '').to_sym
      name = name.to_sym
      if model.key? n
        if n == name
          model[n]
        else
          model[n] = args.first
        end
      elsif model.respond_to?(name)
        model.send(name, args) { yield if block_given? }
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      model.key?(name.to_sym) || model.respond_to?(name) || super
    end
  end
end
