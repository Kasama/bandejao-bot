require './utils/incrementer'

class Bot
  # Module to handle the inline bot
  class Inline
    def initialize(bot)
      @bandejao = bot.bandejao
      @bot = bot
      @id = Incrementer.new
    end

    def handle_inline(message)
      @id.set 0
      results = []
      msg = message.query
      CONST::WEEK.each_with_object(results) do |wday, arr|
        if CONST::WEEK_REGEX[wday] =~ msg
          arr.push result_with_week(wday, msg)
        end
      end
      results.push(result_next)
      #results.push(get_pdf)

      @bot.bot.api.answer_inline_query(
        inline_query_id: message.id,
        results: results,
        switch_pm_text: get_info(message),
        switch_pm_parameter: 'config'
      )
    end

    private # Private methods =================================================

    def get_info(message)
      user = User.find message.from.id
      aliases = @bandejao.get_restaurant_alias(
        user.preferences[:campus],
        user.preferences[:restaurant]
      )
      CONST::TEXTS[:inline_info, aliases[:campus], aliases[:restaurant]]
    end

    def result_next
      text = @bandejao.get_menu
      title = CONST::TEXTS[:inline_title_next]
      inline_result(title, text)
    end

    def result_with_week(wday, msg)
      period = get_period msg
      period_text = get_period_text period
      week_text = CONST::WEEK_NAMES[wday]
      text = @bandejao.get_menu(weekday: wday, period: period)
      title = CONST::TEXTS[:inline_title_specific, week_text, period_text]

      inline_result(title, text)
    end

    def get_period_text(period)
      per = '' unless CONST::PERIODS.include? period
      per ||= CONST::TEXTS[:"inline_#{period}_extra"]
    end

    def get_period(text)
      CONST::PERIODS.each do |per|
        if CONST::PERIOD_REGEX[per] =~ text
          return per
        end
      end
      return nil
    end

    def inline_result(title, text)
      id = @id.inc_after
      content =
        Telegram::Bot::Types::InputTextMessageContent.new(
          message_text: text, parse_mode: CONST::PARSE_MODE
      )
      Telegram::Bot::Types::InlineQueryResultArticle
        .new(
          id: id, title: title,
          input_message_content: content
      )
    end

    def get_pdf
      Telegram::Bot::Types::InlineQueryResultDocument.new(
        type: 'document',
        id: @id.inc_after,
        title: CONST::TEXTS[:inline_pdf],
        #caption: CONST::TEXTS[:inline_pdf],
        document_url: CONST::PDF_SHORT,
        mime_type: 'application/pdf'
      )
    end
  end
end
