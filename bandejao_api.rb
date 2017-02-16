require 'sinatra'
require 'json'

require './bandejao'
require './user.rb'
require './constants.rb'

bandejao = Bandejao.new CONST::MENU_FILE

set :port, 8080
set :environment, :production

get '/' do
  return {status: :failed, message: 'nothing here'}.to_json
end

get /\/date\/(\d?\d)\/(\d?\d)(:?\/(\w+)\/?)?/ do |day, month, _, period|
  if CONST::COMMANDS[:dinner] =~ period
    period = :dinner
  else
    period = :lunch
  end
  text = bandejao.get_bandeco day, month, period, false, false
  { status: get_status(text),
    message: text
  }.to_json
end

get '/next' do
  text = bandejao.get_bandeco
  { status: get_status(text),
    message: text
  }.to_json
end

def get_status(text)
  if text == CONST::TEXTS_HASH[:error_message]
    :failed
  else
    :success
  end
end
