class Bot
	# Module to handle the chat bot
	class Chat
		def initialize(bandejao)
			@bandejao = bandejao
		end

		def handle_inchat(message)
      text, period, tomorrow = handle_command message.text, message.chat.type
			day = month = nil
			if CONST::DATE_REGEX.match message.text
				day, month = %r{(\d?\d)\/(\d?\d)}.match(message.text).captures
			end

			text = @bandejao.get_bandeco day, month, period, false, tomorrow unless text
			text
		end

			private

		# rubocop:disable Metrics/MethodLength
		def handle_command(message, chat_type)
				text = period = tomorrow = nil
        valid = false
				case message
				when CONST::COMMANDS[:lunch]
          valid = true
					period = :lunch
				when CONST::COMMANDS[:dinner]
          valid = true
					period = :dinner
				when CONST::COMMANDS[:tomorrow]
          valid = true
          tomorrow = true
        when CONST::COMMANDS[:next]
          valid = true
				when CONST::COMMANDS[:update]
          valid = true
					tag = @bandejao.update_pdf ? 'success' : 'error'
					text = CONST::TEXTS[:"pdf_update_#{tag}"]
				else
					CONST::COMMANDS.each do |k, v|
						text = CONST::TEXTS[k] if v.match(message)
					end
				end
        unless valid
          text = '' unless chat_type == CONST::CHAT_TYPES[:private]
        end
				[text, period, tomorrow]
		end
	end
end
