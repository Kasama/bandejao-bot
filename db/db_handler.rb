require 'sqlite3'
require 'active_record'
require 'yaml'
require './schema'

module DBHandler
  yaml = YAML.load_file(CONST::DB_CONFIG).deep_symbolize_keys
  db_config = yaml[:database]

  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveRecord::Base.establish_connection(db_config)

  Schema.create_users
  Schema.create_schedules

end
