require './utils/hash_utils'

module USP
  class Model
    attr_reader :model

    def initialize(model)
      puts "making model of #{model.class}"
      @model ||= if model.is_a? Hash
                   model.deep_symbolize_keys
                 else
                   {model: model.symbolize_keys}
                 end
    end

    def method_missing(name, *args, &block)
      n = (name.to_s.gsub /\=/, '').to_sym
      name = name.to_sym
      if model.key? n
        if n == name
          model[n]
        else
          model[n] = args.first
        end
      elsif model.respond_to?(name)
        model.send(name, args, block)
      else
        super
      end
    end

    def respont_to_missing?(name, include_private = false)
      model.key?(name.to_sym) || model.respond_to?(name) || super
    end
  end
end
