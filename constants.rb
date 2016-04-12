module CONST

	Token = ENV['BANDECO_BOT_TOKEN']
	PDF_DOMAIN = "www.prefeitura.sc.usp.br"
	PDF_PATH = "/boletim_informegeral/pdf/cardapio_semanal_restaurante_area_1.pdf"
	USERS_FILE = "users.yaml"
	MASTER_ID = 41487359
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
	}
	TEXTS = {
		help: "Mandando qualquer mensagem para min, eu responderei com o cardápio para o próximo bandejao\n\nAlternativamente, os comandos /almoco e /janta seguidos por uma data retornam o cardápio do almoço/janta do dia representado pela data",
		menu: "Cardapio:\n#{CONST::PDF_DOMAIN}#{CONST::PDF_PATH}",
		alguem: "Alguem sim! Por isso vai ter fila!"

	}

end
