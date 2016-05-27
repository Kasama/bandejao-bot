require 'net/http'
require 'telegram/bot'
require 'yaml'
require File.expand_path './bandejao.rb'
require File.expand_path './constants.rb'

# Probably should separate the console and bot into
# different files, TODO

# This class provides both the telegram bot and console handlers
class Bot
	attr_accessor :bandejao

	def initialize
		@bandejao = Bandejao.new CONST::MENU_FILE
		@users = YAML.load_file(CONST::USERS_FILE)
	end

	def handle_inline_query(day, month, time)
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
		content =
				Telegram::Bot::Types::InputTextMessageContent.new(
						message_text: text, parse_mode: CONST::PARSE_MODE
				)
		Telegram::Bot::Types::InlineQueryResultArticle
				.new(
						id: id, title: title,
						input_message_content: content
				)
	end

	def handle_inline(message)
		results = []
		msg = message.query
		results.push(handle_inline_with_date(msg)) if CONST::DATE_REGEX.match msg
		results.push(handle_inline_without_date)
	end

	def handle_inline_without_date
		text = bandejao.get_bandeco
		title = CONST::TEXTS[:inline_title_next]
		inline_result(1, title, text)
	end

	def handle_inline_with_date(msg)
			day, month, extra = %r{(\d?\d)\/(\d?\d)(.*)}.match(msg).captures
			text = handle_inline_query day, month, extra
			title =
					CONST::TEXTS[:inline_title_specific, day, month, get_period(extra)]
			inline_result(2, title, text)
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
			tag = bandejao.update_pdf ? 'success' : 'error'
			text = CONST::TEXTS[:"pdf_update_#{tag}"]
		else
			CONST::COMMANDS.each do |k, v|
				text = CONST::TEXTS[k] if v.match(message.text)
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
				status = bandejao.update_pdf ? 'success' : 'fail'
				puts CONST::CONSOLE[:"down_#{status}"]
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
end

Bot.new.run
