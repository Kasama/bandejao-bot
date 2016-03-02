require 'net/http'
require 'telegram/bot'
require File.expand_path './constants.rb'

class Bot

	def initialize
		@try = 0
	end

	def handle_inline(message)
		[Telegram::Bot::Types::InlineQueryResultArticle.new(id: 1, title: "Manutenção", message_text: "Estou em manutenção, favor ver o cardapio em #{CONST::PDF_DOMAIN}#{CONST::PDF_PATH}")]
	end

	def run_bot
		begin
			Telegram::Bot::Client.run(CONST::Token) do |bot|
				bot.listen do |message|
					case message
					when Telegram::Bot::Types::InlineQuery
						begin
							results = handle_inline message
							bot.api.answer_inline_query(inline_query_id: message.id, results: results)
						rescue => e
							puts e
							puts "something went wrong in the inline query"
						end
					else
						begin
							bot.api.send_message(chat_id: message.chat.id, text: "Estou em manutenção, favor ver o cardapio em #{CONST::PDF_DOMAIN}#{CONST::PDF_PATH}")
						rescue => e
							puts e
							puts "Something when wrong in chat"
						end
					end
				end
			end
		rescue =>e
			puts e
			if @try < 10
				puts "rerunning"
				@try = @try + 1
				run_bot
			end
		end
	end

	def handle_console(bot_thread)
		quit = false
		until quit do
			print ">> "
			cmd = gets.chomp
			case cmd
				when /quit/
					puts "Quitting.."
					bot_thread.exit
					quit = true
				when /download|update/
					puts "Downloading new pdf..."
					if bandejao.update_pdf
						puts "Success!"
					else
						puts "Download Failed"
					end
				when /clear|cls|clc/
					print "\e[H\e[2J"
				else
					puts "Invalid command: #{cmd}"
			end
		end
	end

	def run
		bot_thread = Thread.new do
			run_bot
			puts "Bot has quit"
		end
		handle_console bot_thread
		bot_thread.join
	end

end

bot = Bot.new
bot.run
