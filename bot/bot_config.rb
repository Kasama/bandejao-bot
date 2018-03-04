require './utils/constants'

class Bot
  class Config
    def initialize(bot)
      @bandejao = bot.bandejao
      @bot = bot
    end

    def start(user, chat, exists = false)
      buttons = [
        button(text: CONST::TEXTS[:config_change_button], data: 'config'),
        button(text: CONST::TEXTS[:config_cancel_button], data: 'cancel')
      ]
      restaurants = get_user_restaurants user
      send_message(
        chat,
        CONST::TEXTS[
          :config_main_menu,
          restaurant_list(restaurants)
        ],
        markup(buttons)
      )
    end

    def handle_callback(callback)
      case callback.data
      when /config/
        main_menu(callback)
      when /cancel/
        cancel(callback)
      when /restaurant_(.+)&campus_(.+)/
        restaurant = $1.to_sym
        campus = $2.to_sym
        select_restaurant(callback, campus, restaurant)
      when /campus_(.+)/
        campus = $1.to_sym
        select_campus(callback, campus)
      end
    end

    private # Private methods =================================================

    def restaurant_list(restaurants)
      restaurants.map { |restaurant|
        restaurant[:campus_alias] + ', ' + restaurant[:restaurant_alias]
      }.join("\n  - ")
    end

    def main_menu(callback)
      restaurants = get_user_restaurants callback.from

      buttons = get_campi_buttons restaurants

      edit_message(
        callback.message,
        CONST::TEXTS[
          :config_select_campus,
          restaurant_list(restaurants)
        ],
        markup(buttons)
      )
    end

    def cancel(callback)
      restaurants = get_user_restaurants callback.from
      edit_message(
        callback.message,
        CONST::TEXTS[
          :config_cancel,
          restaurant_list(restaurants)
        ],
        nil
      )
    end

    def select_restaurant(callback, campus, restaurant)
      aliases = @bandejao.get_restaurant_alias(
        campus,
        restaurant
      )
      # edit_message(
      #   callback.message,
      #   CONST::TEXTS[
      #     :config_selected,
      #     aliases[:campus],
      #     aliases[:restaurant]
      #   ],
      #   nil
      # )
      configure_user(
        callback.from,
        {
          campus: campus,
          campus_alias: aliases[:campus],
          restaurant: restaurant,
          restaurant_alias: aliases[:restaurant]
        }
      )
      main_menu callback
    end

    def select_campus(callback, campus)
      campus_model = @bandejao.api.restaurants[campus]

      prefs = get_user_restaurants callback.from

      restaurants = prefs.map {|r| r[:restaurant]}
      buttons = campus_model.model.each_with_object([]) do |(k, v), o|
        if v.is_a? USP::Restaurant
          text = get_emoji(restaurants, k) + v.alias
          o.push button(text: text, data: "restaurant_#{k}&campus_#{campus}")
        end
      end
      buttons.push button(text: CONST::TEXTS[:config_back], data: 'config')
      edit_message(
        callback.message,
        CONST::TEXTS[:config_select_restaurant, campus_model.alias],
        markup(buttons)
      )
    end

    def get_campi_buttons(restaurants)
      campi = restaurants.map {|r| r[:campus]}
      buttons = @bandejao.api.restaurants.each_with_object([]) do |(k, c), o|
        if c.restaurants.size == 1
          o.push button(
            text: get_emoji(campi, k) + c.alias,
            data: "restaurant_#{c.restaurants.first}&campus_#{k}"
          )
        else
          o.push button(
            text: get_emoji(campi, k) + c.alias + ' ' + CONST::MORE_EMOJI,
            data: "campus_#{k}"
          )
        end
      end
      buttons.push button(
        text: CONST::TEXTS[:config_cancel_button],
        data: 'cancel'
      )
      buttons
    end

    def configure_user(user, options)
      u = User.find user.id
      u.restaurants.push options unless u.restaurants.delete options
      u.save
    end

    def get_user_restaurants(telegram_user)
      user = User.find telegram_user.id
      user.restaurants
    end

    def is_restaurant_selected?(telegram_user, restaurant)
      restaurants = get_user_restaurants telegram_user
      restaurants.include restaurant
    end

    def markup(buttons)
      Telegram::Bot::Types::InlineKeyboardMarkup.new(
        inline_keyboard: buttons
      )
    end

    def button(options)
      options[:callback_data] = options[:data] if options[:data]
      Telegram::Bot::Types::InlineKeyboardButton.new(options)
    end

    def edit_message(message, new_text, markup = nil, parse = CONST::PARSE_MODE)
      options = {
        chat_id: message.chat.id,
        message_id: message.message_id,
        text: new_text,
        parse_mode: parse,
        reply_markup: markup
      }
      if message.text == new_text
        @bot.bot.api.edit_message_reply_markup(options)
      else
        @bot.bot.api.edit_message_text(options)
      end
    end

    def send_message(chat, text, markup = nil, parse = CONST::PARSE_MODE)
      @bot.bot.api.send_message(
        chat_id: chat.id,
        text: text,
        parse_mode: parse,
        reply_markup: markup
      )
    end

    def get_emoji(a, b)
      if a.include? b
        return CONST::CHECKED_BOX_EMOJI + ' '
      else
        return CONST::UNCHECKED_BOX_EMOJI + ' '
      end
    end

  end
end
