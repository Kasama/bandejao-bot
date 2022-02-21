source 'https://rubygems.org'
ruby '3.0.0'

gem 'telegram-bot-ruby'
# gem 'pdf-reader'
gem 'sinatra'
  gem 'thin'

gem 'json'
#gem 'json', github: 'flori/json', branch: 'v1.8'
#gem 'activerecord'
#gem 'activesupport'
gem 'rufus-scheduler'
gem 'parallel'
gem 'standalone_migrations'

group :production do
	gem 'pg'
end

group :development do
	gem 'sqlite3'
end

group :development, :test do
  gem "rerun"
end
