class Bot
  class Subscription
    def initialize(bot)
      @bandejao = bot.bandejao
      @bot = bot
    end

    def start(subscribe, message, exists = false)
      user = message.from
      chat = message.chat
      
      if chat.type != 'private'
        is_admin = get_chat_member(chat, user)
        if is_admin == "creator" || is_admin == "administrator"
          return Schedule.handle_subscription(subscribe, message)
        end
        return false
      end

      return Schedule.handle_subscription(subscribe, message)
    end

    private # Private methods =================================================

    def get_chat_member(chat, user)
      @bot.bot.api.get_chat_member(
        chat_id: chat.id,
        user_id: user.id
      )
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