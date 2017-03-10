require './usp/usp'

module USP
  class Bandejao
    def initialize
      @api = API.new
    end

    def get_menu(weekday = nil, period = nil)
      weekday = CONST::WEEK[Time.now.wday] unless CONST::WEEK.include? weekday
    end
  end
end
