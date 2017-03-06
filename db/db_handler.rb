require 'active_record'
require 'yaml'
require './db/schema'

if CONST::ENVIRONMENT == 'production'
  require 'pg'
else
  require 'sqlite3'
end

module DBHandler
  configuration = if CONST::ENVIRONMENT == 'production'
                    :production
                  else
                    :database
                  end
  yaml = YAML.load_file(CONST::DB_CONFIG).deep_symbolize_keys
  db_config = yaml[configuration]

  ActiveRecord::Base.logger = Logger.new(STDOUT)
  ActiveRecord::Base.establish_connection(db_config)

  Schema.create_users
  Schema.create_schedules
end
