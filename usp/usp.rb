require './utils/inflections'

module USP
  module_function
  def symbolize_name(name)
    special = ActiveSupport::Inflector.transliterate(name)
    no_quotes = special.titleize.gsub(/"|'/, '').gsub(/\./, ' ')
    underscored = no_quotes.split(' ').join('').underscore
    underscored.to_sym
  end
end
