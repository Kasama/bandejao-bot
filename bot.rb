require './bot_inline'
require './bot_chat'
require './bandejao'
require './constants'
require 'telegram/bot'

# This class is responsible for the telegram bot
class Bot
  attr_accessor :bandejao
  attr_accessor :bot

  def initialize
    @bandejao = Bandejao.new CONST::MENU_FILE
    @inline = Inline.new @bandejao
    @chat = Chat.new @bandejao, self
    @bot = nil
    @scheduler = Scheduler.new
  end

  def run
    loop do
      begin
        handle_bot
      rescue => e
        puts e
        puts e.backtrace
        puts CONST::CONSOLE[:bot_problem]
      end
    end
  end

  # rubocop:disable Metrics/MethodLength
  def handle_bot
    Telegram::Bot::Client.run(CONST::Token) do |bot|
      @bot = bot
      puts "==== Initializing Scheduler"
      @scheduler.setup self
      puts "==== Running Bot"
      bot.listen do |message|
        telegram_user = message.from
        if telegram_user
          user = User.find_by_id telegram_user.id
          if user.nil?
            User.create(
              id: telegram_user.id,
              username: telegram_user.username,
              first_name: telegram_user.first_name,
              last_name: telegram_user.last_name
            )
          else
            user.update(
              username: telegram_user.username,
              first_name: telegram_user.first_name,
              last_name: telegram_user.last_name,
              updated_at: Time.now
            )
          end
        end
        case message
        when Telegram::Bot::Types::InlineQuery
          handle :inline, message
        when Telegram::Bot::Types::Message
          # If the message is a reply to this bot's message,
          # or a message sent 'via' this bot, we can ignore the request
          handle(:chat, message) unless group_constraints message
        else
          noop
        end
      end
    end
  end

  def group_constraints(message)
    is_group = message.chat.type != CONST::CHAT_TYPES[:private]
    is_reply = message.reply_to_message
    # Workaround as the Telegram API doesn't diferentiate
    # between a normal message and a message sent 'via' a bot
    has_entities = message.entities.first
    has_header = CONST::PERIOD_HEADERS =~ message.text
    if has_entities
      is_via_bot = message.entities.first.type == 'bold' && has_header
    else
      is_via_bot = false
    end

    is_group && (is_reply || is_via_bot)
  end

  def handle(type, *args)
    send(:"run_#{type}", *args)
  rescue => e
    puts e
    puts CONST::CONSOLE[:"#{type}_problem"]
  end

  def run_inline(message)
    results = @inline.handle_inline message
    @bot.api.answer_inline_query(
      inline_query_id: message.id,
      results: results
    )
  end

  def run_chat(message)
    text = @chat.handle_inchat message
    send_message(message.chat, text)
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

  def send_message(chat, text)
    if chat.type == CONST::CHAT_TYPES[:private]
      reply = get_keyboard chat
    else
      return if text.empty?
      reply = nil
    end
    @bot.api.send_message(
      chat_id: chat.id,
      text: text,
      parse_mode: CONST::PARSE_MODE,
      reply_markup: reply
    )
  end

  def noop
  end
end
