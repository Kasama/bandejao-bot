require 'active_record'
require 'yaml'
require 'erb'
require './db/user'
require './db/schedule'
require 'pg'

# A module to manage the Schema and database stuff
module DBHandler
  def self.init
    configuration = CONST::ENVIRONMENT == 'production' ? :production : :database
    puts "==== Got env #{configuration}"
    parsed_configs = ERB.new(File.read(CONST::DB_CONFIG)).result
    yaml = YAML.load(parsed_configs).deep_symbolize_keys
    db_config = yaml[configuration]
    puts "==== Got config #{db_config.inspect}"
    if db_config.has_key? :url
      db_config = db_config[:url]
    end

    ActiveRecord::Base.logger = Logger.new(STDOUT)
    ActiveRecord::Base.establish_connection(db_config)
  end
end
