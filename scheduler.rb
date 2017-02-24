require 'rufus-scheduler'

class Scheduler

  def initialize(bot)
    @scheduler = Rufus::Scheduler.new
    @bot = bot
  end

  def schedule(period = :lunch, user = nil, chat = nil)
    cron = CONST::CRON_EXP[period]
    return unless user
    return unless cron
    return unless chat.is_a? Telegram::Bot::Types::Chat

    s = Schedule.find_by_chat_id_and_command chat.id, period.to_s
    unless existing
      s = Schedule.create(
        user_id: user.id,
        chat_id: chat.id,
        cronwhen: cron,
        command: period.to_s
      )
    end

    @scheduler.cron s.cronwhen do
      @bot.api.send_message(
        chat_id: s.chat_id,

      )
    end
  end

end
