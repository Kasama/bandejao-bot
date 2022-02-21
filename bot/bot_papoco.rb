require './utils/constants'

class Bot
  class Papoco
    def initialize(bot)
      @bandejao = bot.bandejao
      @bot = bot
    end

    def start(chat, exists = false)
      prng = Random.new( Time.now().to_i )
      shots = 11
      boom = "POOOW"
      if prng.rand(100) >= 90
        boom = "..."
      end

      while shots > 0 do
        num = prng.rand(1..shots)
        if num > shots
          num = shots
        end
        shots -= num
        # send_message(
        #   chat,
        #   "pra " * num
        # )
      end
      # send_message(
      #   chat,
      #   boom
      # )

    end

    private # Private methods =================================================

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
