require 'sinatra/base'
require 'json'

require './bandejao'
require './user.rb'
require './constants.rb'

class API < Sinatra::Base

  set :port, CONST::API_PORT
  set :environment, :production

  before do
    @bandejao = Bandejao.new CONST::MENU_FILE unless @bandejao
  end

  get /\/date\/(\d?\d)\/(\d?\d)(:?\/(\w+)\/?)?/ do |day, month, _, period|
    if CONST::COMMANDS[:dinner] =~ period
      period = :dinner
    else
      period = :lunch
    end
    text = @bandejao.get_bandeco day, month, period, false, false
    { status: get_status(text),
      message: text
    }.to_json
  end

  get '/next' do
    text = @bandejao.get_bandeco
    { status: get_status(text),
      message: text
    }.to_json
  end

  def get_status(text)
    if /kasama/i =~ text
      :failed
    else
      :success
    end
  end

  get '/*' do
    return {status: :failed, message: 'nothing here'}.to_json
  end

end
