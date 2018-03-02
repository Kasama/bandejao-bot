module CONST
  TOKEN = ENV['BANDECO_BOT_TOKEN'].freeze
  ENVIRONMENT = ENV['RACK_ENV'].freeze
  USP_API_KEY = ENV['USP_API_KEY'].freeze

  USP_API_URL = 'https://uspdigital.usp.br/rucard/servicos/'.freeze
  USP_RESTAURANTS_PATH = '/restaurants'.freeze
  USP_MENU_PATH = '/menu/%s'.freeze

  DEFAULT_CAMPUS = :campus_de_sao_carlos
  DEFAULT_CAMPUS_ALIAS = 'São Carlos'.freeze
  DEFAULT_RESTAURANT = :restaurante_area1
  DEFAULT_RESTAURANT_ALIAS = 'Área 1'.freeze

  PARSE_MODE = 'Markdown'.freeze

  MASTER_ID = 41_487_359.freeze
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
  MENU_FILE = './tmp/bandeco.pdf'.freeze
  DB_CONFIG = './db/config.yml'.freeze

  CRON_EXP = {
    lunch: '0 0 11 * * MON-SAT',
    # lunch: '0 55 11 * * MON-FRI',
    # dinner: '0 0 22 * * MON-SAT'
    dinner: '0 0 17 * * MON-FRI'
  }.freeze
  MAX_THREADS = 100.freeze

	PUSP_NAME = 'Prefeitura'.freeze

  LUNCH_END_TIME = '14:30'
  DINNER_END_TIME = '20:00'
  PERIODS = [:lunch, :dinner].freeze
  PERIOD_HEADERS = /.+,.+\n(?:Almoço|Jantar) de .+:\n/.freeze
  DATE_REGEX = %r{\d?\d\/\d?\d.*$}.freeze
  PERIOD_REGEX = {
    lunch: /almo(?:ç|c)o/i,
    dinner: /jantar?/i
  }.freeze

  CLEAR_SCREEN = "\e[H\e[2J".freeze

  CHAT_TYPES = {
    private: 'private',
    group: 'group',
    channel: 'channel',
    supergroup: 'supergroup'
  }.freeze

  WEEK = [
    :sunday,
    :monday,
    :tuesday,
    :wednesday,
    :thursday,
    :friday,
    :saturday
  ].freeze
  WEEK_NAMES = {
    sunday: 'Domingo',
    monday: 'Segunda',
    tuesday: 'Terça',
    wednesday: 'Quarta',
    thursday: 'Quinta',
    friday: 'Sexta',
    saturday: 'Sábado',
  }.freeze
  WEEK_REGEX = {
    sunday: /d(?:o|u)m(?:ingo)?/i,
    monday: /seg(?:unda)?(?:(?: |-)feira)?/i,
    tuesday: /ter(?:c|ça)?(?:(?: |-)feira)?/i,
    wednesday: /qua(?:rta)?(?:(?: |-)feira)?/i,
    thursday: /qui(?:nta)?(?:(?: |-)feira)?/i,
    friday: /sex(?:ta)?(?:(?: |-)feira)?/i,
    saturday: /s(?:a|á)bado/i
  }.freeze

  CALLBACKS = {
    initial: 'teste',
  }

  MAIN_COMMANDS = [
    'Próximo',
    %w(Almoço Jantar),
    :subscribe,
    %w(Configurações Ajuda)
  ].freeze

  MAIN_COMMAND_SUBSCRIBE = 'Inscrever (WIP)'.freeze
  MAIN_COMMAND_UNSUB = 'Desinscrever'.freeze

  SUBSCRIBE = {
    create: {
      true => 'Inscrição realizada com sucesso, tenha em mente que essa funcionalidade ainda está em desenvolvimento. Por favor reporte qualquer problema usando o comando /feedback',
      false => 'Não foi possível realizar a inscrição',
    }.freeze,
    destroy: {
      true => 'Inscrição removida com sucesso',
      false => 'Não foi possível remover a inscrição',
    }.freeze
  }.freeze

  COMMANDS = {
    start: /\/start/i,
    help: /help|ajuda/i,
    next: /next|pr(?:ó|o)xim(?:o|a)/i,
    lunch: PERIOD_REGEX[:lunch],
    dinner: PERIOD_REGEX[:dinner],
    menu: /card(?:a|á)pio/i,
    update: /update/i,
    tomorrow: /\bamanh(?:a|ã)\b/i,
    subscribe: /subscribe|inscrever/i,
    unsubscribe: /unsubscribe|des(?:in|en?)screver/i,
    config: /\bconfig(?:ura(?:r|(?:c|ç)(?:o|õ)es)|\b)|\bpref(?:er(?:e|ê)nc(?:es|ias)|\b)/i,
    feedback: /\b(?:feedback|report)\b/i,
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
    callback_problem: 'Something went wrong in config',
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
    "/almoco [<Dia da Semana>] - Envia o cardápio do almoço do dia indicado (hoje caso não indicado)\n" \
    "/jantar [<Dia da Semana>] - Envia o cardápio do jantar do dia indicado (hoje caso não indicado)\n" \
    "/configuracoes - Abre o menu de configurações, que permite alterar o restaurante atual\n" \
    "/inscrever - Cadastra o chat para receber o cardápio para a próxima refeição antes do restaurante abrir, todos os dias (seg-sab 11:00 e seg-sex 17:00)\n" \
    "/desinscrever - Remove a inscrição efetuada pelo comando acima\n" \
    "/ajuda - Envia essa mensagem\n\n" \
    "/feedback <TEXTO> - Envia o texto especificado para o desenvolvedor do bot. Pode ser usado para reportar problemas, erros, sugerir funcionalidades, etc\n" \
    "Também é possível entrar em contato direto com o desenvolvedor @Kasama, para qualquer dificuldade\n\n" \
    "O código fonte desse bot está disponível em #{CONST::BOT_SOURCE}",
    group_help: 'Para evitar mensagens grandes no grupo, clique no botão abaixo e aperte o "start" para ler a ajuda',
    help_text: 'Ajuda',
    start: 'Bem vindo ao BandejaoBot. envie /ajuda para uma descrição detalhada de funcionalidades',
    menu: "Cardapio: #{CONST::PDF_SHORT}",
    alguem: 'Alguém sim! Por isso vai ter fila!',
    inline_lunch_extra: ' no almoço',
    inline_dinner_extra: ' no jantar',
    inline_info: '%s, %s. Toque para alterar',
    inline_title_next: 'Mostrar cardápio da próxima refeição',
    inline_title_period: 'Mostrar cardápio de hoje%s',
    inline_title_specific: 'Mostrar cardápio para %s%s',
    inline_pdf: 'Mostrar pdf do cardápio da semana',
    config_back: '<< Voltar',
    config_cancel_button: 'Cancelar',
    config_change_button: 'Alterar Restaurante',
    config_main_menu: "*Restaurante atual:\n%s, %s*.\nSelecione uma opção",
    config_select_campus: "*Restaurante atual:\n%s, %s*.\nSelecione um novo Campus abaixo",
    config_select_restaurant: "*%s*:\n Selecione um Restaurante abaixo",
    config_selected: 'Restaurante *%s, %s* selecionado',
    config_cancel: "Operação cancelada\nRestaurante atual:\n*%s, %s*",
    error_message:
    "\nO restaurante está fechado ou o"\
    " cardápio ainda não foi atualizado.\n"\
    'Você pode olhar o link do cardapio para ter certeza: '\
    "#{CONST::PDF_SHORT}\n"\
    'Caso isso seja um erro, avise o @Kasama (t.me/Kasama) ou envie um feedback com o comando /feedback',
    fim_bandeco: 'O bandejão está fechado! Use /help para mais informações',
    pdf_update_success: 'PDF foi atualizado com sucesso',
    pdf_update_error: 'O PDF não foi atualizado',
    feedback_success: 'Feedback enviado com sucesso',
    feedback_fail: 'Feedback vazio não foi enviado, por favor use /feedback <mensagem> para enviar um feedback',
    dinner_header: "*%s, %s\nJantar de %s (%s):*\n%s%s",
    lunch_header: "*%s, %s\nAlmoço de %s (%s):*\n%s%s",
    calories_footer: "\n\n_Valor energético médio: %sKcal_",
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
