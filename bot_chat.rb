class Bot
	# Module to handle the chat bot
	class Chat
		def initialize(bandejao)
			@bandejao = bandejao
		end

		def handle_inchat(message)
			text, period = handle_command message.text
			day = month = nil
			if CONST::DATE_REGEX.match message.text
				day, month = %r{(\d?\d)\/(\d?\d)}.match(message.text).captures
			end

			text = @bandejao.get_bandeco day, month, period unless text
			text
		end

			private

		# rubocop:disable Metrics/MethodLength
		def handle_command(message)
				text = period = nil
				case message
				when CONST::COMMANDS[:lunch]
					period = :lunch
				when CONST::COMMANDS[:dinner]
					period = :dinner
				when CONST::COMMANDS[:update]
					tag = @bandejao.update_pdf ? 'success' : 'error'
					text = CONST::TEXTS[:"pdf_update_#{tag}"]
				else
					CONST::COMMANDS.each do |k, v|
						text = CONST::TEXTS[k] if v.match(message)
					end
				end
				[text, period]
		end
	end
end
