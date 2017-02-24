require './bot_inline'
require './bot_chat'
require './bandejao'
#require './user.rb'
require 'telegram/bot'

# This class is responsible for the telegram bot
class Bot
	attr_accessor :bandejao

	def initialize
		@bandejao = Bandejao.new CONST::MENU_FILE
		@inline = Inline.new @bandejao
		@chat = Chat.new @bandejao
	end

	def run
		loop do
			begin
				handle_bot
			rescue => e
				puts e
				puts CONST::CONSOLE[:bot_problem]
			end
		end
	end

		private

	# rubocop:disable Metrics/MethodLength
	def handle_bot
		Telegram::Bot::Client.run(CONST::Token) do |bot|
			bot.listen do |message|
				#@users[message.from.id] ||= message.from
        telegram_user = message.from
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
				case message
				when Telegram::Bot::Types::InlineQuery
					handle :inline, bot, message
				when Telegram::Bot::Types::Message
          # If the message is a reply to this bot's message,
          # or a message sent 'via' this bot, we can ignore the request
          unless (
              message.chat.type != CONST::CHAT_TYPES[:private] && (
                message.reply_to_message ||
                #Workaround to tell when a message was send 'via' this bot
                message.entities.first.type = 'bold'
              )
          )
            handle :chat, bot, message
          end
				else
					noop
				end
			end
		end
	end

	def handle(type, *args)
		send(:"run_#{type}", *args)
	rescue => e
		puts e
		puts CONST::CONSOLE[:"#{type}_problem"]
	end

  def get_keyboard
    commands = CONST::MAIN_COMMANDS.map do |value|
      if value.is_a? Array
        value.map do |v|
          Telegram::Bot::Types::KeyboardButton.new(text: v)
        end
      else
        Telegram::Bot::Types::KeyboardButton.new(text: value)
      end
    end

    Telegram::Bot::Types::ReplyKeyboardMarkup.new(
      keyboard: commands,
      resize_keyboard: false
    )
  end

	def run_inline(bot, message)
		results = @inline.handle_inline message
		bot.api.answer_inline_query(
				inline_query_id: message.id,
				results: results
		)
	end

	def run_chat(bot, message)
		text = @chat.handle_inchat message
    if message.chat.type == CONST::CHAT_TYPES[:private]
      reply = get_keyboard
    else
      if text.empty?
        return
      end
      reply = nil
    end
		bot.api.send_message(
				chat_id: message.chat.id,
				text: text,
				parse_mode: CONST::PARSE_MODE,
        reply_markup: reply
		)
	end

	def noop
	end
end
