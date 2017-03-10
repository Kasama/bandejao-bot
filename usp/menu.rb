require './usp/model'

module USP
  class Menu < Model
    def initialize(model)
      @model ||= normalize_week model
    end

    def normalize_week(menu)
      menu
    end
  end
end
