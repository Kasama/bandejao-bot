class Bot
	# Module to handle the chat bot
	class Chat
		def initialize(bandejao, bot)
			@bandejao = bandejao
      @bot = bot
		end

		def handle_inchat(message)
      text, period, tomorrow = handle_command message
			day = month = nil
			if CONST::DATE_REGEX.match message.text
				day, month = %r{(\d?\d)\/(\d?\d)}.match(message.text).captures
			end

			text = @bandejao.get_bandeco day, month, period, false, tomorrow unless text
			text
		end

			private

		# rubocop:disable Metrics/MethodLength
		def handle_command(message)
				text = period = tomorrow = subscribe = nil
        valid = false
        case message.text
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
        when CONST::COMMANDS[:unsubscribe]
          valid = true
          subscribe = :destroy
        when CONST::COMMANDS[:subscribe]
          valid = true
          subscribe = :create
				when CONST::COMMANDS[:update]
          valid = true
					tag = @bandejao.update_pdf ? 'success' : 'error'
					text = CONST::TEXTS[:"pdf_update_#{tag}"]
        when CONST::COMMANDS[:feedback]
          valid = true
          text = send_feedback message
				else
					CONST::COMMANDS.each do |k, v|
            text = CONST::TEXTS[k] if v.match(message.text)
					end
				end
        if subscribe
          success = Schedule.handle_subscription(subscribe, message)
          text = CONST::SUBSCRIBE[subscribe][success]
        end
        tomorrow = CONST::COMMANDS[:tomorrow] =~ message.text
        unless valid
          text = '' unless message.chat.type == CONST::CHAT_TYPES[:private]
        end
				[text, period, tomorrow]
		end

    def send_feedback(message)
      @bot.bot.api.send_message(
        chat_id: CONST::MASTER_ID,
        text: "user (#{message.from.inspect}) enviou feedback:\n#{message.text}"
      )
      "Feedback enviado com sucesso!"
    end

	end
end
