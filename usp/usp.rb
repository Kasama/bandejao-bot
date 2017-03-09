require './usp/http'

class USP
  attr_accessor :http

  def initialize
    @auth_params = {hash: CONST::USP_API_KEY}
    @http = HTTP.new
  end

  def get_restaurants
  end

end
