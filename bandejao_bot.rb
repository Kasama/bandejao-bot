require 'net/http'
require 'pdf-reader'
require 'telegram/bot'
require 'yaml'
require File.expand_path './bandejao.rb'
require File.expand_path './constants.rb'

class Bot
	attr_accessor :bandejao
	attr_accessor :pdf_file

	def initialize
		@pdf_file = CONST::MENU_FILE
		@bandejao = Bandejao.new pdf_file
		@date_regex = /\d?\d\/\d?\d.*$/
		@users = YAML.load_file(CONST::USERS_FILE);
	end

	def handle_menu_query(day, month, time)
			day = bandejao.zero_pad day
			month = bandejao.zero_pad month
			time.chomp!
			horario = nil
			if CONST::COMMANDS[:lunch] === time
				horario = :almoco
			elsif CONST::COMMANDS[:dinner] === time
				horario = :janta
			end
			bandejao.get_bandeco day, month, horario
	end

	def get_horario_name(extra)
			horario_text = ''
			if CONST::COMMANDS[:lunch] === extra
				horario_text = CONST::TEXTS[:inline_lunch_extra]
			elsif CONST::COMMANDS[:dinner] === extra
				horario_text = CONST::TEXTS[:inline_dinner_extra]
			end
	end

	def handle_inline(message)
		results = []
		msg = message.query
		if @date_regex === msg
			day, month, extra = /(\d?\d)\/(\d?\d)(.*)/.match(msg).captures
			text = handle_menu_query day, month, extra
			title = CONST::TEXTS[:inline_title_specific] + "#{day}/#{month}#{get_horario_name(extra)}"
			results.push Telegram::Bot::Types::InlineQueryResultArticle
				.new(id: 2, title: title, message_text: text, parse_mode: 'Markdown')
		end
		text = bandejao.get_bandeco
		title = CONST::TEXTS[:inline_title_next]
		results.push Telegram::Bot::Types::InlineQueryResultArticle
			.new(id: 1, title: title, message_text: text, parse_mode: 'Markdown')
		results
	end

	def handle_inchat(message)
		text = nil
		horario = nil
		day = nil
		month = nil
		case message.text
		when CONST::COMMANDS[:lunch]
			horario = :almoco
		when CONST::COMMANDS[:dinner]
			horario = :janta
		#when CONST::COMMANDS[:users]
		#	if message.from.id == CONST::MASTER_ID
		#		text = @users.to_s
		#	end
		else
			CONST::COMMANDS.each do |k,v|
				if v === message.text
					text = CONST::TEXTS[k]
				end
			end
		end
		if @date_regex === message.text
			day, month = /(\d?\d)\/(\d?\d)/.match(message.text).captures
		end

		text = bandejao.get_bandeco day, month, horario unless text
		text
	end

	def run_bot
		loop do
			begin
				Telegram::Bot::Client.run(CONST::Token) do |bot|
					bot.listen do |message|
						unless @users[message.from.id]
							@users[message.from.id] = message.from
						end
						case message
						when Telegram::Bot::Types::InlineQuery
							begin
								results = handle_inline message
								bot.api.answer_inline_query(inline_query_id: message.id, results: results)
							rescue => e
								puts e
								puts CONST::CONSOLE[:inline_problem]
							end
						else
							text = handle_inchat message
							begin
								bot.api.send_message(chat_id: message.chat.id, text: text, parse_mode: 'Markdown')
							rescue => e
								puts e
								puts CONST::CONSOLE[:chat_problem]
							end
						end
					end
				end
			rescue => e
				puts e
				puts CONST::CONSOLE[:bot_problem]
			end
		end
	end

	def handle_console(bot_thread)
		quit = false
		until quit do
			print CONST::CONSOLE[:prompt]
			cmd = gets.chomp
			case cmd
			when CONST::COMMANDS[:quit]
				puts CONST::CONSOLE[:quitting]
				bot_thread.exit
				quit = true
			when CONST::COMMANDS[:restart]
				puts CONST::CONSOLE[:restarting]
				bot_thread.exit
				exit 1
			when CONST::COMMANDS[:download]
				puts CONST::COMMANDS[:downloading]
				if bandejao.update_pdf
					puts CONST::COMMANDS[:down_success]
				else
					puts CONST::COMMANDS[:down_fail]
				end
			when CONST::COMMANDS[:users]
				@users.each do |k, u|
					puts "---------"
					puts u.first_name
					puts u.last_name
					puts u.username
				end
			when CONST::COMMANDS[:clear]
				print "\e[H\e[2J"
			else
				puts CONST::COMMANDS[:invalid_command] + cmd
			end
		end
	end

	def serialize_and_save(obj)
		File.open(CONST::USERS_FILE, 'w') { |f| f.puts obj.to_yaml }
	end

	def run
		@users = YAML.load_file CONST::USERS_FILE
		unless @users
			@users = {}
			serialize_and_save @users
		end
		bot_thread = Thread.new do
			run_bot
		end
		handle_console bot_thread
		bot_thread.join
		serialize_and_save @users
	end

end

bot = Bot.new
bot.run
