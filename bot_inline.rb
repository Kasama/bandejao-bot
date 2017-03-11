class Bot
	# Module to handle the inline bot
	class Inline
		def initialize(bandejao)
			@bandejao = bandejao
		end

		def handle_inline(message)
			results = []
			msg = message.query
			results.push(handle_inline_with_date(msg)) if CONST::DATE_REGEX.match msg
			results.push(handle_inline_without_date)
      #results.push(inline_result(3, CONST::TEXTS[:inline_pdf], CONST::TEXTS[:menu]))
      results.push(Telegram::Bot::Types::InlineQueryResultDocument.new(
        type: 'document',
        id: 3,
        title: CONST::TEXTS[:inline_pdf],
        #caption: CONST::TEXTS[:inline_pdf],
        document_url: CONST::PDF_SHORT,
        mime_type: 'application/pdf'
      ))
		end

			private

		def handle_inline_without_date
			text = @bandejao.get_menu
			title = CONST::TEXTS[:inline_title_next]
			inline_result(1, title, text)
		end

		def handle_inline_with_date(msg)
			day, month, extra = %r{(\d?\d)\/(\d?\d)(.*)}.match(msg).captures
			text = handle_inline_query day, month, extra
			title =
					CONST::TEXTS[:inline_title_specific, day, month, get_period(extra)]
			inline_result(2, title, text)
		end

		def inline_result(id, title, text)
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

		def handle_inline_query(day, month, time)
			time.chomp!
			period = nil
			CONST::PERIODS.each do |per|
				CONST::COMMANDS[per] =~ time && (period = per)
			end
			@bandejao.get_bandeco day, month, period
		end

		def get_period(extra)
			period = ''
			CONST::PERIODS.each do |per|
				if CONST::COMMANDS[per].match extra
					period = CONST::TEXTS[:"inline_#{per}_extra"]
				end
			end
			period
		end
	end
end
