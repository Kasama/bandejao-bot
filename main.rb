require './utils/constants'
require './bot/bot'
require './console'
require './bandejao_api'
require './scheduler'
require './db/db_handler'

# This is the main module, responsible for launching the program
class Main
  attr_accessor :bot_thread, :api_thread

  def run
    DBHandler.init

    quit = 0
    while quit != 1
      bot = Bot.new
      @bot_thread = Thread.new { bot.run }
      @api_thread = Thread.new { API.run! }
      unless CONST::ENVIRONMENT == 'production'
        console = Console.new @bot_thread, @api_thread
        quit = console.handle_console
      end
      @bot_thread.join
      @api_thread.join
    end
  end

  def shut_down
    @bot_thread.exit
    @api_thread.exit
    exit 0
  end
end

def shut_down(main)
  main.shut_down
end

main = Main.new

trap('SIGTERM') do
  shut_down main
end

trap('SIGINT') do
  shut_down main
end

main.run
