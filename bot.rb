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
		# @users = User.new CONST::USERS_FILE
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
				# @users[message.from.id] ||= message.from
				case message
				when Telegram::Bot::Types::InlineQuery
					handle :inline, bot, message
				when Telegram::Bot::Types::Message
					handle :chat, bot, message
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

	def run_inline(bot, message)
		results = @inline.handle_inline message
		bot.api.answer_inline_query(
				inline_query_id: message.id,
				results: results
		)
	end

	def run_chat(bot, message)
		text = @chat.handle_inchat message
		bot.api.send_message(
				chat_id: message.chat.id,
				text: text,
				parse_mode: CONST::PARSE_MODE
		)
	end

	def noop
	end
end
