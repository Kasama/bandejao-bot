require 'rufus-scheduler'
require 'parallel'

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
        all_schedules = Schedule.includes(:user).to_a
        threads = (all_schedules.size / 5).to_i + 1
        if threads > CONST::MAX_THREADS
          threads = CONST::MAX_THREADS
        end
        bot.bot.api.send_message(
          chat_id: CONST::MASTER_ID,
          text: "Reached schedule at #{now}. Allocating #{ all_schedules.size } messages in #{ threads } threads."
        )
        successes = [0]
        total = [0]
        messages = []
        # Schedule.all.each do |schedule|
        Parallel.each(all_schedules, in_threads: threads) do |schedule|
          begin
            puts "Sending message to @#{schedule.user.username}, #{schedule.user_id} from thread #{Parallel.worker_number}"
            puts "============================================================"
            bot.run_schedule build_message(schedule.user_id, schedule.chat_id), schedule.user.preferences
            successes << 1
            total << 1
          rescue => e
            puts "Could not Send message to @#{schedule.user.username}, #{schedule.user_id}, skipping"
            puts "Error:\n#{e.message}\n======\nStacktrace: #{e.backtrace.join "\n    "}"
            puts "============================================================"
            messages << e.message
            total << 1
          end
        end
        successes = successes.reduce(&:+)
        total = total.reduce(&:+)
        bot.bot.api.send_message(
          chat_id: CONST::MASTER_ID,
          text: "Finished schedule. Took #{Time.now - now}s.\n Successful: #{successes}/#{total} #{successes*100/total}%\nErrors:"
        )
        messages.each do |m|
          bot.bot.api.send_message(
            chat_id: CONST::MASTER_ID,
            text: m
          )
        end
        bot.bot.api.send_message(
          chat_id: CONST::MASTER_ID,
          text: "Finished error messages."
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
