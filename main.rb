require File.expand_path './constants'
require File.expand_path './bot'
require File.expand_path './console'
require File.expand_path './bandejao_api'
require File.expand_path './db/db_handler'

# This is the main module, responsible for launching the program
module Main
		module_function

	def run
    DBHandler.init

    quit = 0
    while quit != 1
      bot = Bot.new
      bot_thread = Thread.new { bot.run }
      api_thread = Thread.new { API.run! }
      unless ENV['ENVIRONMENT'] == 'production'
        console = Console.new bot_thread, api_thread
        quit = console.handle_console
      end
      bot_thread.join
      api_thread.join
    end
	end
end

Main.run
