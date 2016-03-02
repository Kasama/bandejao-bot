require 'net/http'
require 'pdf-reader'
require 'telegram/bot'
require File.expand_path './bandejao.rb'
require File.expand_path './constants.rb'

class Bot
	attr_accessor :bandejao
	attr_accessor :pdf_file

	def initialize
		@pdf_file = 'bandeco.pdf'
		@bandejao = Bandejao.new pdf_file
	end

	def handle_inline(message)
		results = []
		msg = message.query
		if /^\d?\d\/\d?\d.*$/.match msg
			day, month, extra = /(\d?\d)\/(\d?\d)(.*)/.match(msg).captures
			day = bandejao.zero_pad day
			month = bandejao.zero_pad month
			extra.chomp!
			horario = nil
			horario_text = ''
			if /almoço|almoco/ === extra
				horario = :almoco
				horario_text = " no almoço"
			elsif /jantar?/ === extra
				horario = :janta
				horario_text = " no jantar"
			end
			text = bandejao.get_bandeco day, month, horario
			results.push Telegram::Bot::Types::InlineQueryResultArticle
			.new(id: 2, title: "Mostrar cardápio para dia #{day}/#{month}#{horario_text}", message_text: text, parse_mode: 'Markdown')
		end
		text = bandejao.get_bandeco
		results.push Telegram::Bot::Types::InlineQueryResultArticle
		.new(id: 1, title: 'Mostrar cardápio do proximo bandejão', message_text: text, parse_mode: 'Markdown')

		results
	end

	def run_bot
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
					case message.text
					when '/help'
						text = "Mandando qualquer mensagem para min, eu responderei com o cardápio para o próximo bandejao"
					else
						text = bandejao.get_bandeco
					end
					begin
						bot.api.send_message(chat_id: message.chat.id, text: text, parse_mode: 'Markdown')
					rescue => e
						puts e
						puts "Something when wrong in chat"
					end
				end
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
		end
		handle_console bot_thread
		bot_thread.join
	end

end

bot = Bot.new
bot.run
