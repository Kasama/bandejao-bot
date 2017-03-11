require './usp/api'
require './constants'

require 'active_support/core_ext/numeric/time'

module USP
  class Bandejao
    attr_reader :api

    def initialize
      @api = API.new
    end

    def get_menu(options = {})
      weekday, period = get_current_period
      default = {
        weekday: weekday,
        period: period,
        campus: CONST::DEFAULT_CAMPUS,
        restaurant: CONST::DEFAULT_RESTAURANT
      }
      options = assert_options(default, options)

      menu = api.menu options[:campus], options[:restaurant]
      ret = menu[options[:weekday]][options[:period]]
      ret = CONST::TEXTS[
        :"#{options[:period]}_header",
        CONST::WEEK_NAMES[options[:weekday]],
        api.restaurants[options[:campus]].alias,
        api.restaurants[options[:campus]][options[:restaurant]].alias,
        ret
      ]
    end

    def assert_options(default, options)
      return default unless options.is_a? Hash

      options = default.merge options
      rests = api.restaurants
      unless CONST::WEEK.include? options[:weekday]
        options[:weekday] = default[:weekday]
      end
      unless CONST::PERIODS.include? options[:period]
        options[:period] = default[:period]
      end
      unless rests.keys.include? options[:campus]
        options[:campus] = default[:campus]
      end
      unless rests[options[:campus]].keys.include? options[:restaurant]
        options[:campus] = default[:campus]
        options[:restaurant] = default[:restaurant]
      end
      options
    end

    def get_current_period(now = Time.now)
      if now > Time.parse('14:30', now) # after lunch
        if now > Time.parse('20:00', now) # after dinner
          get_current_period((now + 1.day).at_noon) # next day's lunch
        else # before dinner
          [CONST::WEEK[now.wday], :dinner]
        end
      else # before lunch
        [CONST::WEEK[now.wday], :lunch]
      end
    end
  end
end
