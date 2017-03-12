require './constants'

class Bot
  class Config
    def initialize(bot)
      @bandejao = bot.bandejao
      @bot = bot
    end

    def start(chat)
      buttons = @bandejao.api.restaurants.each_with_object([]) do |(k, v), o|
        o.push button(text: v.alias, data: "campus_#{k}")
      end
      send_message(chat, "Selecione um campus", markup(buttons))
    end

    def handle_callback(callback)
      case callback.data
      when /restaurant_(.+)&campus_(.+)/
        restaurant = $1.to_sym
        campus = $2.to_sym
        #send_message(callback.message.chat, "Selected #{campus} and #{restaurant}")
        edit_message(callback.message, "Selected #{campus} and #{restaurant}", nil, nil)
        configure_user(callback.from, {campus: campus, restaurant: restaurant})
      when /campus_(.+)/
        campus = $1.to_sym
        buttons = @bandejao.api.restaurants[campus].model.each_with_object([]) do |(k, v), o|
          if v.is_a? USP::Restaurant
            o.push button(text: v.alias, data: "restaurant_#{k}&campus_#{campus}")
          end
        end
        buttons.push button(text: '<< Voltar', data: 'config')
        edit_message(callback.message, "Selecione um restaurante", markup(buttons))
      end
    end

    private # Private methods =================================================

    def configure_user(user, options)
      u = User.find user.id
      u.preferences = options
      u.save
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
