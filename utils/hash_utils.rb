class Object
  def deep_symbolize_keys
    self
  end
end

class Hash
  def deep_symbolize_keys
    symbolize_keys.tap do |h|
      h.each do |k, v|
        h[k] = v.deep_symbolize_keys
      end
    end
  end
  def symbolize_keys
    each_with_object({}) do |(k, v), o|
      if k.respond_to? :to_sym
        o[k.to_sym] = v
      else
        o[k] = v
      end
    end
  end
end

class Array
  def deep_symbolize_keys
    map(&:deep_symbolize_keys)
  end
end
