require './usp/model'
require './utils/hash_utils.rb'
require './constants'
require 'time'

module USP
  class Menu < Model
    def initialize(model)
      @model ||= normalize_week model.deep_symbolize_keys
      super
    end

    def normalize_week(menu)
      menu.each_with_object({}) do |meal, o|
        date = Date.parse meal[:date]
        o[CONST::WEEK[date.wday]] = meal
      end
    end

    CONST::PERIODS.each do |per|
      define_method per do |week_day|
        return '' unless CONST::WEEK.include? week_day
        model[week_day][per][:menu]
      end
    end
  end
end
