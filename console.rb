# This module is responsible for handling the console
class Console
  def initialize(bot_thread, api_thread = Thread.new {})
		@bot = bot_thread
    @api = api_thread
	end

	def handle_console
		quit = 0
		while quit == 0
			print CONST::CONSOLE[:prompt]
			cmd = gets.chomp
			quit = handle_command(cmd)
		end
    quit
	end

		private

	# rubocop:disable Metric/AbcSize
	# rubocop:disable Metric/CyclomaticComplexity
	# rubocop:disable Metric/MethodLength
	#
	# TODO: Make this better, smells bad
	def handle_command(command)
		quit = 0
		case command
		when CONST::CONSOLE_COMMANDS[:quit]
			puts CONST::CONSOLE[:quitting]
			@bot.exit
      @api.exit
			quit = 1
		when CONST::CONSOLE_COMMANDS[:restart]
			puts CONST::CONSOLE[:restarting]
			@bot.exit
      @api.exit
      quit = 2
			# TODO: return exit code somehow, instead of killing the program
			# exit 1
		when CONST::CONSOLE_COMMANDS[:download]
			puts CONST::CONSOLE[:downloading]
			status = bandejao.update_pdf ? 'success' : 'fail'
			puts CONST::CONSOLE[:"down_#{status}"]
		when CONST::CONSOLE_COMMANDS[:users]
			print_users
		when CONST::CONSOLE_COMMANDS[:clear]
			print CONST::CLEAR_SCREEN
		else
			puts CONST::CONSOLE[:invalid_command, command]
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
