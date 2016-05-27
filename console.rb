# This module is responsible for handling the console
class Console
	def initialize(bot_thread)
		@bot = bot_thread
	end

	def handle_console
		quit = false
		until quit
			print CONST::CONSOLE[:prompt]
			cmd = gets.chomp
			quit = handle_command(cmd)
		end
	end

		private

	# rubocop:disable Metric/AbcSize
	# rubocop:disable Metric/CyclomaticComplexity
	# rubocop:disable Metric/MethodLength
	#
	# TODO: Make this better, smells bad
	def handle_command(command)
		quit = false
		case command
		when CONST::CONSOLE_COMMANDS[:quit]
			puts CONST::CONSOLE[:quitting]
			@bot.exit
			quit = true
		when CONST::CONSOLE_COMMANDS[:restart]
			puts CONST::CONSOLE[:restarting]
			@bot.exit
			# TODO: return exit code somehow, instead of killing the program
			exit 1
		when CONST::CONSOLE_COMMANDS[:download]
			puts CONST::CONSOLE[:downloading]
			status = bandejao.update_pdf ? 'success' : 'fail'
			puts CONST::CONSOLE[:"down_#{status}"]
		when CONST::CONSOLE_COMMANDS[:users]
			print_users
		when CONST::CONSOLE_COMMANDS[:clear]
			print CONST::CLEAR_SCREEN
		else
			puts CONST::CONSOLE[:invalid_command, cmd]
		end
		quit
	end

	def print_users
		users = User.new CONST::USERS_FILE
		users.each_value do |u|
			puts '---------'
			puts u.first_name
			puts u.last_name
			puts u.username
		end
	end
end
