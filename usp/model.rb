require './utils/hash_utils'
class Model
  attr_reader :model

  def initialize(model)
    @model = model.deep_symbolize_keys
  end

  def method_missing(name, *args, &block)
    if model.key? name.to_sym
      model[name.to_sym]
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
