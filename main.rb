require './constants'
require './bot'
require './console'
require './bandejao_api'
require './scheduler'
require './db/db_handler'

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
      unless CONST::ENVIRONMENT == 'production'
        console = Console.new bot_thread, api_thread
        quit = console.handle_console
      end
      bot_thread.join
      api_thread.join
      scheduler_thread.exit
    end
	end
end

Main.run
