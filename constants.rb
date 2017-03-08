module CONST
  Token = ENV['BANDECO_BOT_TOKEN'].freeze
  ENVIRONMENT = ENV['RACK_ENV'].freeze
  BOT_SOURCE = 'github.com/Kasama/bandejao-bot'.freeze
  PDF_DOMAIN = 'www.prefeitura.sc.usp.br'.freeze
  PDF_PATH =
    '/boletim_informegeral/pdf/'\
    'cardapio_semanal_restaurante_area_1.pdf'.freeze
  PDF_SHORT = 'http://goo.gl/v97wdA'.freeze
  API_PORT = if ENV['PORT']
               ENV['PORT'].to_i.freeze
             else
               8273.freeze
             end
  USERS_FILE = 'users.yml'.freeze
  MENU_FILE = 'bandeco.pdf'.freeze
  DB_CONFIG = './db/config.yml'.freeze
  MASTER_ID = 41_487_359
  PERIODS = [:lunch, :dinner].freeze
  CRON_EXP = {
    lunch: '0 5 11 * * MON-FRI',
    # lunch: '30 21 23 * * MON-FRI',
    # dinner: '0 0 22 * * MON-SAT'
    dinner: '0 0 17 * * MON-SAT'
  }
  SUBSCRIBE = {
    create: {
      true => 'Inscrição realizada com sucesso, tenha em mente que essa funcionalidade ainda está em desenvolvimento. Por favor reporte qualquer problema usando o comando /feedback',
      false => 'Não foi possível realizar a inscrição',
    },
    destroy: {
      true => 'Inscrição removida com sucesso',
      false => 'Não foi possível remover a inscrição',
    }
  }
  PERIOD_HEADERS = /\A(?:Almoço \(\d\d?\/\d\d?\)|Jantar \(\d\d?\/\d\d?\)):/.freeze
  PARSE_MODE = 'Markdown'.freeze
  DATE_REGEX = %r{\d?\d\/\d?\d.*$}
  CLEAR_SCREEN = "\e[H\e[2J".freeze
  CHAT_TYPES = {
    private: 'private',
    group: 'group',
    channel: 'channel',
    supergroup: 'supergroup'
  }.freeze

  MAIN_COMMANDS = [
    'Próximo', 'Almoço',
    'Jantar', 'Cardápio',
    :subscribe, 'Ajuda'
  ].freeze

  MAIN_COMMAND_SUBSCRIBE = 'Inscrever (WIP)'
  MAIN_COMMAND_UNSUB = 'Desinscrever'

  COMMANDS = {
    start: /\/start/i,
    help: /help|ajuda/i,
    next: /next|pr(?:ó|o)xim(?:o|a)/i,
    lunch: /almo(?:ç|c)o/i,
    dinner: /jantar?/i,
    menu: /card(?:a|á)pio/i,
    update: /update/i,
    tomorrow: /\bamanh(?:a|ã)\b/i,
    subscribe: /subscribe|inscrever/i,
    unsubscribe: /unsubscribe|des(?:in|en?)screver/i,
    feedback: /feedback|report/i,
    alguem: /\balgu(?:e|é)m\b/i
  }.freeze

  CONSOLE_COMMANDS = {
    users: /users/i,
    quit: /quit/i,
    restart: /res(?:tart|et)/i,
    download: /download|update/i,
    clear: /cl(?:ear|s|c)/i
  }.freeze

  CONSOLE_HASH = {
    inline_problem: 'Something went wrong in the inline query',
    chat_problem: 'Something went wrong in chat',
    welcome_problem: 'Something went wrong in the welcome message',
    bot_problem: 'Something went wrong in the bot communication',
    quitting: 'Quitting..',
    restarting: 'Restarting...',
    downloading: 'Downloading new pdf...',
    down_success: 'Success!',
    down_fail: 'Download Failed',
    invalid_command: 'Invalid command: %s',
    prompt: '>> '
  }.freeze

  TEXTS_HASH = {
    help:
    "Enviando uma mensagem com qualquer texto você receberá o cardápio para a próxima refeição.\n\n" \
    "Comandos: \n" \
    "/proximo - Envia o cardápio da próxima refeição, da mesma forma que enviar qualquer texto\n" \
    "/almoco [<DIA>/<MES>] - Envia o cardápio do almoço do dia indicado (hoje caso não indicado)\n" \
    "/jantar [<DIA>/<MES>] - Envia o cardápio do jantar do dia indicado (hoje caso não indicado)\n" \
    "-- Em ambos /almoço e /jantar pode-se colocar a palavra 'amanha' para receber o cardápio do dia seguinte\n" \
    "/cardapio - Envia o PDF do cardápio do jeito que é disponibilizado pela prefeitura do campus\n" \
    "/inscrever - Cadastra o chat para receber o cardápio para a próxima refeição antes do restaurante abrir, todos os dias (seg-sab 11:00 e seg-sex 17:00)\n" \
    "/desinscrever - Remove a inscrição efetuada pelo comando acima\n" \
    "/ajuda - Envia essa mensagem\n\n" \
    "/feedback <TEXTO> - Envia o texto especificado para o desenvolvedor do bot. Pode ser usado para reportar problemas, erros, sugerir funcionalidades, etc\n" \
    "Também é possível entrar em contato direto com o desenvolvedor @Kasama, para qualquer dificuldade\n\n" \
    "O código fonte desse bot está disponível em #{CONST::BOT_SOURCE}",
    start: 'Bem vindo ao BandejaoBot. envie /ajuda para uma descrição detalhada de funcionalidades',
    menu: "Cardapio: #{CONST::PDF_SHORT}",
    alguem: 'Alguém sim! Por isso vai ter fila!',
    inline_lunch_extra: ' no almoço',
    inline_dinner_extra: ' no jantar',
    inline_title_next: 'Mostrar cardápio do próximo bandejão',
    inline_title_specific: "Mostrar cardápio para dia %d/%d %s",
    inline_pdf: 'Mostrar pdf do cardápio da semana',
    error_message:
    "\nO restaurante está fechado ou o"\
    " cardápio ainda não foi atualizado.\n"\
    'Você pode olhar o link do cardapio para ter certeza: '\
    "#{CONST::PDF_SHORT}\n"\
    'Caso isso seja um erro, avise o @Kasama (t.me/Kasama) ou envie um feedback com o comando /feedback',
    fim_bandeco: 'O bandejão está fechado! Use /help para mais informações',
    pdf_update_success: 'PDF foi atualizado com sucesso',
    pdf_update_error: 'O PDF não foi atualizado',
    dinner_header: '*Jantar (%s/%s):*%s',
    lunch_header: '*Almoço (%s/%s):*%s',
    wtf: 'WTF!?'
  }.freeze

  # TODO: refactor this, DRY!
  # This module serves as a hash accessor
  module CONSOLE
    module_function

    def [](message, *params)
      CONSOLE_HASH[message] % params
    end
  end

  # This module serves as a hash accessor
  module TEXTS
    module_function

    def [](message, *params)
      TEXTS_HASH[message] % params
    end
  end
end
