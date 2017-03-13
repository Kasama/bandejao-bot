require './utils/constants'

class Bot
  # Module to handle the chat bot
  class Chat
    def initialize(bot)
      @bandejao = bot.bandejao
      @bot = bot
    end

    def handle_inchat(message)
      text, period, tomorrow = handle_command message
      weekday = nil
      CONST::WEEK.each do |wday|
        if CONST::WEEK_REGEX[wday] =~ message.text
          weekday ||= wday
        end
      end

      user = User.find message.from.id
      prefs = user.preferences

      unless text
        text = @bandejao.get_menu(
          weekday: weekday,
          period: period,
          campus: prefs[:campus],
          restaurant: prefs[:restaurant]
        )
      end
      send_message(message.chat, text)
    end

    private # Private methods =================================================

    # rubocop:disable Metrics/MethodLength
    def handle_command(message)
      text = period = tomorrow = subscribe = nil
      valid = false
      case message.text
      when CONST::COMMANDS[:lunch]
        valid = true
        period = :lunch
      when CONST::COMMANDS[:dinner]
        valid = true
        period = :dinner
      when CONST::COMMANDS[:tomorrow]
        valid = true
        tomorrow = true
      when CONST::COMMANDS[:next]
        valid = true
      when CONST::COMMANDS[:unsubscribe]
        valid = true
        subscribe = :destroy
      when CONST::COMMANDS[:subscribe]
        valid = true
        subscribe = :create
      when CONST::COMMANDS[:config]
        valid = true
        text = ''
        @bot.start_config message.from, message.chat
      when CONST::COMMANDS[:update]
        valid = true
        tag = @bandejao.update_pdf ? 'success' : 'error'
        text = CONST::TEXTS[:"pdf_update_#{tag}"]
      when CONST::COMMANDS[:feedback]
        valid = true
        text = send_feedback message
      else
        CONST::COMMANDS.each do |k, v|
          text = CONST::TEXTS[k] if v.match(message.text)
        end
      end
      if subscribe
        success = Schedule.handle_subscription(subscribe, message)
        text = CONST::SUBSCRIBE[subscribe][success]
      end
      tomorrow = CONST::COMMANDS[:tomorrow] =~ message.text
      unless valid
        text = '' unless message.chat.type == CONST::CHAT_TYPES[:private]
      end
      [text, period, tomorrow]
    end

    def send_feedback(message)
      send_message(
        Telegram::Bot::Types::Chat.new(id: CONST::MASTER_ID, type: :private),
        "user (#{message.from.inspect}) enviou feedback:\n#{message.text}",
        nil
      )
      CONST::TEXTS[:feedback_success]
    end

    def get_keyboard(chat)
      commands = CONST::MAIN_COMMANDS.map do |value|
        if value.is_a? Array
          value.map do |v|
            keyboard_button v, chat
          end
        else
          keyboard_button value, chat
        end
      end

      Telegram::Bot::Types::ReplyKeyboardMarkup.new(
        keyboard: commands,
        resize_keyboard: false
      )
    end

    def keyboard_button(value, chat)
      if value == :subscribe
        value = if Schedule.find_by_chat_id chat.id
                  CONST::MAIN_COMMAND_UNSUB
                else
                  CONST::MAIN_COMMAND_SUBSCRIBE
                end
      end
      Telegram::Bot::Types::KeyboardButton.new(text: value)
    end

    def send_message(chat, text, parse = CONST::PARSE_MODE)
      return if text.empty?
      if chat.type == CONST::CHAT_TYPES[:private]
        reply = get_keyboard chat
      else
        reply = nil
      end
      @bot.bot.api.send_message(
        chat_id: chat.id,
        text: text,
        parse_mode: parse,
        reply_markup: reply
      )
    end

  end
end
