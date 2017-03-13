require './utils/hash_utils'
require './utils/inflections'
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
      aliasify_model
      created
    end

    def created
      @created ||= Time.now
    end

    def valid?
      created.after 20.hours.ago
    end

    def size
      (@model.keys - [:alias, :name]).size
    end

    def aliasify_model
      aliased_name = model[:name]

      aliased_name = aliased_name.gsub(/"|'/i, '')
      aliased_name = aliased_name.gsub(/\s*campus\s*(de)?\s*/i, '')
      aliased_name = aliased_name.gsub(/\s*restaurante\s*/i, '')
      aliased_name = aliased_name.gsub(/\s*fac\.?\s*/i, '')
      aliased_name = aliased_name.gsub(/pusp.(c)/i, CONST::PUSP_NAME)

      aliased_name = aliased_name.singularize.mb_chars.titleize.to_s

      model[:alias] = aliased_name.titleize #handles edge cases for acronyms
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
        self.model.send(name, *args) { yield if block_given? }
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      model.key?(name.to_sym) || model.respond_to?(name) || super
    end
  end
end
