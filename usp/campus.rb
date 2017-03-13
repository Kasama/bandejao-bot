require './usp/model'

module USP
  class Campus < Model
    def restaurants
      model.keys - [:alias, :name]
    end
  end
end
