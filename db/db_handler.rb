require 'active_record'
require 'yaml'
require 'erb'
require './db/schema'

if CONST::ENVIRONMENT == 'production'
  require 'pg'
else
  require 'sqlite3'
end

# A module to manage the Schema and database stuff
module DBHandler
  def self.init
    configuration = CONST::ENVIRONMENT == 'production' ? :production : :database
    puts "==== Got env #{configuration}"
    parsed_configs = ERB.new(File.read(CONST::DB_CONFIG)).result
    yaml = YAML.load(parsed_configs).deep_symbolize_keys
    db_config = yaml[configuration]
    puts "==== Got confg #{db_config.inspect}"

    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.establish_connection(db_config)

    Schema.create_users
    Schema.create_schedules
  end
end
