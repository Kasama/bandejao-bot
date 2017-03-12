require './constants'

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
      prefs = User.find(user.id).preferences
      aliases = @bandejao.get_restaurant_alias(
        prefs[:campus],
        prefs[:restaurant]
      )
      send_message(
        chat,
        CONST::TEXTS[
          :config_main_menu,
          aliases[:campus],
          aliases[:restaurant]
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

    def main_menu(callback)
      buttons = get_campi_buttons

      prefs = get_user_preferences callback.from
      aliases = @bandejao.get_restaurant_alias(
        prefs[:campus],
        prefs[:restaurant]
      )
      text = edit_message(
        callback.message,
        CONST::TEXTS[
          :config_select_campus,
          aliases[:campus],
          aliases[:restaurant]
        ],
        markup(buttons)
      )
    end

    def cancel(callback)
      prefs = get_user_preferences callback.from
      aliases = @bandejao.get_restaurant_alias(
        prefs[:campus],
        prefs[:restaurant]
      )
      edit_message(
        callback.message,
        CONST::TEXTS[
          :config_cancel,
          aliases[:campus],
          aliases[:restaurant]
        ],
        nil
      )
    end

    def select_restaurant(callback, campus, restaurant)
      aliases = @bandejao.get_restaurant_alias(
        campus,
        restaurant
      )
      edit_message(
        callback.message,
        CONST::TEXTS[
          :config_selected,
          aliases[:campus],
          aliases[:restaurant]
        ],
        nil
      )
      configure_user(callback.from, {campus: campus, restaurant: restaurant})
    end

    def select_campus(callback, campus)
      campus_model = @bandejao.api.restaurants[campus]
      buttons = campus_model.model.each_with_object([]) do |(k, v), o|
        if v.is_a? USP::Restaurant
          o.push button(text: v.alias, data: "restaurant_#{k}&campus_#{campus}")
        end
      end
      buttons.push button(text: CONST::TEXTS[:config_back], data: 'config')
      edit_message(
        callback.message,
        CONST::TEXTS[:config_select_restaurant, campus_model.alias],
        markup(buttons)
      )
    end

    def get_campi_buttons
      buttons =@bandejao.api.restaurants.each_with_object([]) do |(k, c), o|
        if c.restaurants.size == 1
          o.push button(
            text: c.alias,
            data: "restaurant_#{c.restaurants.first}&campus_#{k}"
          )
        else
          o.push button(
            text: c.alias,
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
      u.preferences = options
      u.save
    end

    def get_user_preferences(telegram_user)
      user = User.find telegram_user.id
      user.preferences
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

  end
end
