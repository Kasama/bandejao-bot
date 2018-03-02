require './usp/api'
require './utils/constants'
require './utils/time'

require 'active_support/core_ext/numeric/time'

module USP
  class Bandejao
    attr_reader :api

    def initialize
      @api = API.new
    end

    def get_menu(options = {})
      options = normalize_options options

      menu = api.menu options[:campus], options[:restaurant]
      day = menu[options[:weekday]]
      ret = day[options[:period]]
      calories = api.calories_footer ret

      date = Date.parse day[:date]
      aliases = get_restaurant_alias(options[:campus], options[:restaurant])
      tnow = Time.now
      puts "DEBUG - date is: #{date.strftime("%b %d, %Y - %H:%M:%S.%24N")}"
      puts "DEBUG -  now is: #{tnow.strftime("%b %d, %Y - %H:%M:%S.%24N")}"
      puts "DEBUG - dwek is: #{date.at_beginning_of_week.strftime("%b %d, %Y - %H:%M:%S.%24N")}"
      puts "DEBUG - twek is: #{tnow.at_beginning_of_week.strftime("%b %d, %Y - %H:%M:%S.%24N")}"
      if date < tnow.at_beginning_of_week
        CONST::TEXTS[
          :late_update,
          aliases[:campus],
          aliases[:restaurant]
        ]
      else
        CONST::TEXTS[
          :"#{options[:period]}_header",
          aliases[:campus],
          aliases[:restaurant],
          CONST::WEEK_NAMES[options[:weekday]],
          date.strftime("%d/%m"),
          ret,
          calories
        ]
      end
    end

    def get_restaurant_alias(campus, restaurant)
      c = api.restaurants[campus]
      r = c[restaurant]
      {campus: c.alias, restaurant: r.alias}
    end

    private # Private methods =================================================

    def normalize_options(options)
      weekday, period = get_current_period
      default = {
        weekday: weekday,
        period: period,
        campus: CONST::DEFAULT_CAMPUS,
        restaurant: CONST::DEFAULT_RESTAURANT
      }
      assert_options(default, options)
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
      unless rests[options[:campus]].key? options[:restaurant]
        options[:campus] = default[:campus]
        options[:restaurant] = default[:restaurant]
      end
      options
    end

    def get_current_period(now = Time.now)
      if now.after Time.parse(CONST::LUNCH_END_TIME, now)
        if now.after Time.parse(CONST::DINNER_END_TIME, now)
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
