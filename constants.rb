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
		clear: /clear|cls|clc/
	}
	
end
