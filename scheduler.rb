require 'rufus-scheduler'

class Scheduler

  def initialize(bot)
    @scheduler = Rufus::Scheduler.new frequency: 0.9

    Thread.new do
      while bot.bot.nil?
        sleep(0.5)
      end
      CONST::PERIODS.each do |per|
        @scheduler.cron CONST::CRON_EXP[per] do
          Schedule.all.each do |schedule|
            user = Telegram::Bot::Types::User.new(
              id: schedule.user_id
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
            bot.run_chat message
          end
        end
      end
    end

  end

  def schedule(period = :lunch, user = nil, chat = nil)
    # cron = CONST::CRON_EXP[period]
    # return unless cron
    return unless user.is_a? Telegram::Bot::Types::User
    return unless chat.is_a? Telegram::Bot::Types::Chat

    s = Schedule.find_by_chat_id_and_command chat.id, period.to_s
    unless s
      s = Schedule.create(
        user_id: user.id,
        chat_id: chat.id,
        cronwhen: '0 19 18 * * *',
        command: period.to_s
      )
    end

    puts "scheduler is #{@scheduler.inspect}"
    @scheduler.cron s.cronwhen do
      message = Telegram::Bot::Types::Message.new(
        text: '.',
        from: user,
        chat: chat
      )
      Bot.new.run_chat @bot, message
    end
  end

end
