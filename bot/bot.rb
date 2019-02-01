require './bot/bot_inline'
require './bot/bot_chat'
require './bot/bot_config'
require './bot/bot_papoco'
require './bot/bot_subscription'
require './utils/constants'
require './usp/bandejao'

require 'telegram/bot'

# This class is responsible for the telegram bot
class Bot
  attr_accessor :bandejao
  attr_accessor :bot

  def initialize
    @bandejao = USP::Bandejao.new
    @inline = Inline.new self
    @chat = Chat.new self
    @config = Config.new self
    @papoco = Papoco.new self
    @subscription = Subscription.new self
    @bot = Telegram::Bot::Client.run(CONST::TOKEN) { |bot| bot }
    @scheduler = Scheduler.new
  end

  def run
    puts '==== Initializing Scheduler'
    @scheduler.setup self
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

  def run_schedule(respond_to_msg, restaurants = nil)
    run_chat respond_to_msg, restaurants
  end

  def start_config(user, chat)
    @config.start(user, chat)
  end

  def start_subscription(user, chat)
    @subscription.start(user, chat)
  end

  def start_papoco(chat)
    @papoco.start(chat)
  end

  private # Private methods ===================================================

  # rubocop:disable Metrics/MethodLength
  def handle_bot
    puts "==== Running Bot"
    Telegram::Bot::Client.run(CONST::TOKEN) { |bot|
      bot.listen do |message|
        update_user message.from
        case message
        when Telegram::Bot::Types::Message
          # If the message is a reply to this bot's message,
          # or a message sent 'via' this bot, we can ignore the request
          handle(:chat, message) unless group_constraints message
        when Telegram::Bot::Types::InlineQuery
          handle(:inline, message)
        when Telegram::Bot::Types::CallbackQuery
          handle(:callback, message)
        else
          noop
        end
      end
    }
  end

  def update_user(telegram_user)
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
    puts e.backtrace
    puts CONST::CONSOLE[:"#{type}_problem"]
  end

  def run_inline(message)
    @inline.handle_inline message
  end

  def run_chat(message, restaurants = nil)
    @chat.handle_inchat message, restaurants
  end

  def run_callback(message)
    @config.handle_callback message
  end

  def noop
  end
end
