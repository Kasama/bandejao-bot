require './utils/http'
require './utils/hash_utils'
require './constants'
require './usp/restaurant'
require './usp/menu'
require 'active_support/inflector'
require 'json'

module USP
  class API
    attr_accessor :http

    def initialize
      @auth_params = {hash: CONST::USP_API_KEY}
      @http = HTTP.new CONST::USP_API_URL
      @restaurants = nil
      @menus = nil
    end

    def restaurants
      return @restaurants if @restaurants
      res = http.post(CONST::USP_RESTAURANTS_PATH, @auth_params)
      json = JSON.parse res.body
      campi = json.deep_symbolize_keys
      @restaurants = campi.each_with_object({}) do |campus, h|
        key = USP.symbolize_name campus[:name]
        h[key] = campus[:restaurants].each_with_object({}) do |restaurant, r|
          key = USP.symbolize_name restaurant[:alias]
          r[key] = Restaurant.new restaurant
        end
      end
    end

    def menu(restaurant)
      @menu ||= {}
    end

    def menus
      @menus ||= restaurants.each_with_object({}) do |(name, campus), c|
        c[name] = campus.each_with_object({}) do |(rest_name, restaurant), r|
          res = http.post(CONST::USP_MENU_PATH % restaurant.id, @auth_params)
          json = JSON.parse res.body
          menu = json.deep_symbolize_keys
          r[rest_name] = if menu[:message][:error]
                           nil
                         else
                           Menu.new menu
                         end
        end
      end
    end
  end

  module_function
  def symbolize_name(name)
    special = ActiveSupport::Inflector.transliterate(name)
    no_quotes = special.titleize.gsub(/"|'/, '')
    underscored = no_quotes.split(' ').join('').underscore
    underscored.to_sym
  end
end
