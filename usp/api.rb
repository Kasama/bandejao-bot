require './utils/constants'
require './utils/http'
require './utils/hash_utils'
require './usp/usp'
require './usp/restaurant'
require './usp/campus'
require './usp/menu'
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

    def restaurants(force_update = false)
      exists = @restaurants.is_a? Restaurant
      return @restaurants if exists && @restaurants.valid? && !force_update

      res = http.post(CONST::USP_RESTAURANTS_PATH, @auth_params)
      json = JSON.parse res.body
      campi = json.deep_symbolize_keys
      restaurants_hash = campi.each_with_object({}) do |campus, h|
        key = USP.symbolize_name campus[:name]
        campi_h = campus[:restaurants].each_with_object({}) do |restaurant, r|
          k = USP.symbolize_name restaurant[:alias]
          r[k] = Restaurant.new restaurant
        end
        campi_h[:name] = campus[:name]
        h[key] = Campus.new campi_h
      end
      @restaurants = restaurants_hash
    end

    def menu(campus, restaurant, force = false)
      @menu ||= {}
      @menu[campus] ||= {}
      exists = @menu[campus][restaurant].is_a? Menu
      if exists && @menu[campus][restaurant].valid? && !force
        return @menu[campus][restaurant]
      end

      path = CONST::USP_MENU_PATH % restaurants[campus][restaurant].id
      res = http.post(path, @auth_params)
      menu = JSON.parse(res.body).deep_symbolize_keys

      @menu[campus][restaurant] = if menu[:message][:error]
                                    nil
                                  else
                                    Menu.new menu[:meals]
                                  end
    end

    def calories_footer(menu_entry)
      cal = menu_entry.calories
      if cal.empty? || cal.to_i == 0
        ''
      else
        CONST::TEXTS[:calories_footer, cal]
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
end
