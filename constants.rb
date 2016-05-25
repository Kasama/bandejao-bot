module CONST

	Token = ENV['BANDECO_BOT_TOKEN'].freeze
	PDF_DOMAIN = "www.prefeitura.sc.usp.br".freeze
	PDF_PATH = "/boletim_informegeral/pdf/cardapio_semanal_restaurante_area_1.pdf".freeze
	USERS_FILE = "users.yaml".freeze
	MENU_FILE = "bandeco.pdf".freeze
	MASTER_ID = 41487359
	PERIODS = [:lunch, :dinner].freeze
	PARSE_MODE = "Markdown".freeze
	DATE_REGEX = /\d?\d\/\d?\d.*$/.freeze
	CLEAR_SCREEN = "\e[H\e[2J".freeze
	COMMANDS = {
		help: '/help',
		lunch: /\/almo(?:ç|c)o/,
		dinner: /\/jantar?/,
		menu: /\/cardapio/,
		users: /\/users/,
		quit: /quit/,
		restart: /restart|reset/,
		download: /download|update/,
		clear: /clear|cls|clc/,
		alguem: /\balgu(?:e|é)m\b/i
	}.freeze

	CONSOLE_HASH = {
		inline_problem: "Something went wrong in the inline query",
		chat_problem: "Something when wrong in chat",
		bot_problem: "Something went wrong in the bot communication",
		quitting: "Quitting..",
		restarting: "Restarting...",
		downloading: "Downloading new pdf...",
		down_success: "Success!",
		down_fail: "Download Failed",
		invalid_command: "Invalid command: %s",
		prompt: ">> "

	}.freeze

	TEXTS_HASH= {
		help: "Mandando qualquer mensagem para min, eu responderei com o cardápio para o próximo bandejao\n\nAlternativamente, os comandos /almoco e /janta seguidos por uma data retornam o cardápio do almoço/janta do dia representado pela data",
		menu: "Cardapio:\n#{CONST::PDF_DOMAIN}#{CONST::PDF_PATH}",
		alguem: "Alguém sim! Por isso vai ter fila!",
		inline_lunch_extra: " no almoço",
		inline_dinner_extra: " no jantar",
		inline_title_next: "Mostrar cardápio do próximo bandejão",
		inline_title_specific: "Mostrar cardápio para dia %d/%d %s",
		error_message: "\nOu não tem bandeco nesse dia ou o cardápio ainda não foi atualizado\nVocê pode olhar aqui para ter certeza #{CONST::PDF_DOMAIN}#{CONST::PDF_PATH}\nCaso eu esteja errado, avise o @Kasama",
		fim_bandeco: "Ja era seu *bandeco*, fi. Use /help para mais opções",
		pdf_update_success: "PDF foi atualizado com sucesso",
		pdf_update_error: "O PDF não foi atualizado",
		dinner_header: "*Janta (%d/%d)*:%s",
		lunch_header: "*Almoço (%d/%d)*:%s",
		wtf: "WTF!?"

	}.freeze

	# TODO: refactor this, DRY!
	class CONSOLE
		def self.[](message, *params)
			CONSOLE_HASH[message] % params
		end
	end

	class TEXTS
		def self.[](message, *params)
			TEXTS_HASH[message] % params
		end
	end

end
