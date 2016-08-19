require File.expand_path 'reader'

file = ENV['file']
puts "reading file #{file}"
puts '-----------------------'

reader = Reader.new(file)
text = reader.get_text

puts text
