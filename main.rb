require File.expand_path './constants'
require File.expand_path './bot'
require File.expand_path './console'

# This is the main module, responsible for launching the program
module Main
		module_function

	def run
		bot = Bot.new
		bot_thread = Thread.new { bot.run }
		unless ENV['HAS_CONSOLE'] == 'false'
			console = Console.new bot_thread
			console.handle_console
		end
		bot_thread.join
	end
end

Main.run
