require './constants'
require './utils/http'
require './utils/hash_utils'
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

    def menu(campus, restaurant)
      @menu ||= {}
      @menu[campus] ||= {}
      exists = @menu[campus][restaurant].is_a? Menu
      if exists && @menu[campus][restaurant].valid?
        return @menu[campus][restaurant]
      end
      puts "making for #{campus} e #{restaurant}"

      path = CONST::USP_MENU_PATH % restaurants[campus][restaurant].id
      res = http.post(path, @auth_params)
      menu = JSON.parse(res.body).deep_symbolize_keys

      @menu[campus][restaurant] = if menu[:message][:error]
                                    nil
                                  else
                                    Menu.new menu[:meals]
                                  end
    end

    def menus
      restaurants.each do |campus_name, campus|
        campus.each_key do |rest_name|
          menu(campus_name, rest_name)
        end
      end
    end
  end

  module_function
  def symbolize_name(name)
    special = ActiveSupport::Inflector.transliterate(name)
    no_quotes = special.titleize.gsub(/"|'/, '').gsub(/\./, ' ')
    underscored = no_quotes.split(' ').join('').underscore
    underscored.to_sym
  end
end
