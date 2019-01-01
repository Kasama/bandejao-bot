require './utils/constants'

class Bot
  # Module to handle the chat bot
  class Chat
    def initialize(bot)
      @bandejao = bot.bandejao
      @bot = bot
    end

    def handle_inchat(message, restaurants = nil)
      send_typing message.chat
      if CONST::COMMANDS[:help] =~ message.text && message.chat.type != CONST::CHAT_TYPES[:private]
        send_message(message.chat, CONST::TEXTS[:group_help], nil, help_button)
        return
      end
      text, period, tomorrow = handle_command message
      weekday = nil
      CONST::WEEK.each do |wday|
        if CONST::WEEK_REGEX[wday] =~ message.text
          weekday ||= wday
        end
      end

      unless restaurants
        user = User.find message.from.id
        restaurants = user.restaurants
      end

      if text
        send_message(message.chat, text)
        return
      end

      restaurants.each do |restaurant|
        send_typing message.chat
        text = @bandejao.get_menu(
          weekday: weekday,
          period: period,
          campus: restaurant[:campus],
          restaurant: restaurant[:restaurant]
        )
        send_message(message.chat, text)
      end
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
      when CONST::COMMANDS[:papoco]
        valid = true
        text = ''
        @bot.start_papoco message.chat
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
        "[#{message.from.first_name} #{message.from.last_name}](tg://user?id=#{message.from.id}) Enviou um feedback:"
      )
      send_message(
        Telegram::Bot::Types::Chat.new(id: CONST::MASTER_ID, type: :private),
        "#{message.text}",
        nil
      )
      if /\A\s*\/*\s*(?:feedback|report)(?:@bandejao.+bot)?\s*\z/i =~ message.text
        if message.chat.type == CONST::CHAT_TYPES[:private]
          CONST::TEXTS[:feedback_fail]
        else
          ''
        end
      else
        CONST::TEXTS[:feedback_success]
      end
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

    def help_button
      Telegram::Bot::Types::InlineKeyboardMarkup.new(
        inline_keyboard: [
          Telegram::Bot::Types::InlineKeyboardButton.new(
            text: CONST::TEXTS[:help_text],
            url: 'https://telegram.me/BandejaoBot?start=help'
          )
        ]
      )
    end

    def send_typing(chat)
      @bot.bot.api.send_chat_action(
        chat_id: chat.id,
        action: 'typing'
      )
    end

    def send_message(chat, text, parse = CONST::PARSE_MODE, markup = nil)
      return if text.empty?
      if markup.nil? && chat.type == CONST::CHAT_TYPES[:private]
        markup = get_keyboard chat
      end
      @bot.bot.api.send_message(
        chat_id: chat.id,
        text: text,
        parse_mode: parse,
        reply_markup: markup
      )
    end

  end
end
