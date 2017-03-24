require 'rufus-scheduler'

class Scheduler

  def initialize
    puts "======================================================== ran scheduler"
    @scheduler = Rufus::Scheduler.new frequency: 0.9
    @done = false
  end

  def setup(bot)
    return if @done
    @done = true
    CONST::PERIODS.each do |per|
      @scheduler.cron CONST::CRON_EXP[per] do
        puts "==================== REACHED SCHEDULE ========================"
        now = Time.now
        bot.bot.api.send_message(
          chat_id: CONST::MASTER_ID,
          text: "Reached schedule at #{now}."
        )
        Schedule.all.each do |schedule|
          puts "Sending message to #{schedule.user_id}"
          puts "============================================================"
          message = build_message(schedule.user_id, schedule.chat_id)
          bot.run_schedule message
        end
        bot.bot.api.send_message(
          chat_id: CONST::MASTER_ID,
          text: "Finished schedule. Took #{Time.now - now}s"
        )
      end
    end
  end

  def build_message(user, chat_id)
    Telegram::Bot::Types::Message.new(
      text: CONST::MAIN_COMMANDS.first,
      from: Telegram::Bot::Types::User.new(id: user),
      chat: Telegram::Bot::Types::Chat.new(
        type: CONST::CHAT_TYPES[:group],
        id: chat_id
      )
    )
  end
end
