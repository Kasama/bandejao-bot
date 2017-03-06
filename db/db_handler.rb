require 'active_record'
require 'yaml'
require './db/schema'

if CONST::ENVIRONMENT == 'production'
  require 'pg'
else
  require 'sqlite3'
end

module DBHandler
  def self.init
    yaml = YAML.load_file(CONST::DB_CONFIG).deep_symbolize_keys
    db_config = yaml[:database]

    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.establish_connection(db_config)

    Schema.create_users
    Schema.create_schedules
  end
end
