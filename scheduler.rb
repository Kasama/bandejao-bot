require 'rufus-scheduler'

class Scheduler

  def initialize
    puts '======================================================== ran scheduler'
    @scheduler = Rufus::Scheduler.new frequency: 0.9
    @done = false
  end

  def setup(bot)
    return if @done
    @done = true
    CONST::PERIODS.each do |per|
      @scheduler.cron CONST::CRON_EXP[per] do
        puts '==================== REACHED SCHEDULE ========================'
        Schedule.all.each do |schedule|
          u = User.find_by_id schedule.user_id
          user = Telegram::Bot::Types::User.new(
            id: u.id
          )
          puts "Sending message to #{u.first_name}"
          puts '============================================================'
          bot.bot.api.send_message(
            chat_id: CONST::MASTER_ID,
            text: "Sending message to #{u.first_name} (#{u.inspect})"
          )
          chat = Telegram::Bot::Types::Chat.new(
            id: schedule.chat_id,
            type: CONST::CHAT_TYPES[:group]
          )
          message = Telegram::Bot::Types::Message.new(
            text: '/proximo',
            from: user,
            chat: chat
          )
          bot.run_schedule message
        end
      end
    end
  end
end
