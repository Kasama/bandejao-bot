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
        member = get_chat_member(chat, user)["result"]
        is_admin = member["status"] == "creator" || member["status"] == "administrator"
        if is_admin
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

  end
end