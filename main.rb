require File.expand_path './constants'
require File.expand_path './bot'
require File.expand_path './console'

# This is the main module, responsible for launching the program
module Main
		module_function

	def run
		bot = Bot.new
		bot_thread = Thread.new { bot.run }
		console = Console.new bot_thread
		console.handle_console
		bot_thread.join
	end
end

Main.run
