require 'net/http'
require 'pdf-reader'
require 'telegram/bot'
require 'yaml'
require File.expand_path './bandejao.rb'
require File.expand_path './constants.rb'

# Probably should separate the console and bot into
# different files, TODO

class Bot
	attr_accessor :bandejao

	def initialize
		@bandejao = Bandejao.new CONST::MENU_FILE
		@users = YAML.load_file(CONST::USERS_FILE)
	end

	def handle_menu_query(day, month, time)
			day = bandejao.zero_pad day
			month = bandejao.zero_pad month
			time.chomp!
			period = nil
			CONST::PERIODS.each do |per|
				CONST::COMMANDS[per].match time && period = per
			end
			bandejao.get_bandeco day, month, period
	end

	def get_period(extra)
			period = ''
			CONST::PERIODS.each do |per|
				if CONST::COMMANDS[per].match extra
					period = CONST::TEXTS[:"inline_#{per}_extra"]
				end
			end
			period
	end

	def inline_result(id, title, text)
		Telegram::Bot::Types::InlineQueryResultArticle
			.new(
				id: id,
				title: title,
				message_text: text,
				parse_mode: CONST::PARSE_MODE
			)
	end

	def handle_inline(message)
		results = []
		msg = message.query
		if CONST::DATE_REGEX.match msg
			day, month, extra = %r{(\d?\d)\/(\d?\d)(.*)}.match(msg).captures
			text = handle_menu_query day, month, extra
			title =
				CONST::TEXTS[:inline_title_specific, day, month, get_period(extra)]
			results.push inline_result(2, title, text)
		end
		text = bandejao.get_bandeco
		title = CONST::TEXTS[:inline_title_next]
		results.push inline_result(1, title, text)
		results
	end

	def handle_inchat(message)
		text = nil
		period = nil
		case message.text
		when CONST::COMMANDS[:lunch]
			period = :lunch
		when CONST::COMMANDS[:dinner]
			period = :dinner
		when CONST::COMMANDS[:update]
			text = if bandejao.update_pdf
				CONST::TEXTS[:pdf_update_success]
			else
				CONST::TEXTS[:pdf_update_error]
			end
		else
			CONST::COMMANDS.each do |k, v|
				v.match(message.text) && text = CONST::TEXTS[k]
			end
		end

		day = month = nil
		if CONST::DATE_REGEX.match message.text
			day, month = %r{(\d?\d)\/(\d?\d)}.match(message.text).captures
		end

		text = bandejao.get_bandeco day, month, period unless text
		text
	end

	def run_bot
		loop do
			begin
				Telegram::Bot::Client.run(CONST::Token) do |bot|
					bot.listen do |message|
						@users[message.from.id] ||= message.from
						case message
						when Telegram::Bot::Types::InlineQuery
							begin
								results = handle_inline message
								bot.api.answer_inline_query(
									inline_query_id: message.id,
									results: results
								)
							rescue => e
								puts e
								puts CONST::CONSOLE[:inline_problem]
							end
						else
							text = handle_inchat message
							begin
								bot.api.send_message(
									chat_id: message.chat.id,
									text: text,
									parse_mode: CONST::PARSE_MODE
								)
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
		until quit
			print CONST::CONSOLE[:prompt]
			cmd = gets.chomp
			case cmd
			when CONST::CONSOLE_COMMANDS[:quit]
				puts CONST::CONSOLE[:quitting]
				bot_thread.exit
				quit = true
			when CONST::CONSOLE_COMMANDS[:restart]
				puts CONST::CONSOLE[:restarting]
				bot_thread.exit
				exit 1
			when CONST::CONSOLE_COMMANDS[:download]
				puts CONST::CONSOLE[:downloading]
				if bandejao.update_pdf
					puts CONST::CONSOLE[:down_success]
				else
					puts CONST::CONSOLE[:down_fail]
				end
			when CONST::CONSOLE_COMMANDS[:users]
				@users.each_value do |u|
					puts '---------'
					puts u.first_name
					puts u.last_name
					puts u.username
				end
			when CONST::CONSOLE_COMMANDS[:clear]
				print CONST::CLEAR_SCREEN
			else
				puts CONST::CONSOLE[:invalid_command, cmd]
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
		bot_thread = Thread.new { run_bot }
		handle_console bot_thread
		bot_thread.join
		serialize_and_save @users
	end
end

bot = Bot.new
bot.run
