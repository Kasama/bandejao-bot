require 'net/http'

class HTTP
  attr_reader :base_url
  attr_accessor :last_resp

  def initialize(base_url)
    @base_url = if base_url.end_with? '/'
                  base_url.gsub /.\Z/, ''
                else
                  base_url
                end
  end

  def get(path = '/', params = {})
    normalized = normalize_get_params params
    @last_resp = Net::HTTP.get(URI(base_url + path + '?' + normalized))
  end

  def post(path = '/', params = {})
    path = normalize_path path
    @last_resp = Net::HTTP.post_form(URI(base_url + path), params)
  end

  def normalize_get_params(params = {})
    params.each_with_object("") do |(k, v), o|
      o << '&' unless o.empty?
      o << k.to_s
      o << '='
      o << v.to_s
    end
  end

  def normalize_path(path)
    if path.start_with? '/'
      path
    else
      '/' + path
    end
  end
end
