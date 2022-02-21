require 'sinatra/base'
require 'json'

require './user'
require './utils/constants'

class API < Sinatra::Base

  set :port, CONST::API_PORT
  set :environment, :production

  get '/next' do
    { status: get_status(text),
      message: "API not implemented yet"
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
