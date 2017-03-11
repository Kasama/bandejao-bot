require './usp/api'
require './constants'

module USP
  class Bandejao
    attr_reader :api

    def initialize
      @api = API.new
    end

    def get_menu(weekday = nil, period = nil, campus, restaurant)
      weekday = CONST::WEEK[Time.now.wday] unless CONST::WEEK.include? weekday

      menu = api.menu campus, restaurant
      menu[weekday][period]
    end
  end
end
