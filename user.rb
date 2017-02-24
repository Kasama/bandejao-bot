# require 'yaml'
# 
# # This class should handle the users file and keep it updated
# class Users
# 	def initialize(file)
# 		@file = file
# 		refresh
# 	end
# 
# 	def serialize_and_save
# 		File.open(@file, 'w') { |f| f.puts @users.to_yaml }
# 	end
# 
# 	def refresh
# 		@users = YAML.load_file @file
# 		return if @users
# 		@users = {}
# 		serialize_and_save
# 	end
# 
# 	def []=(key, new_value)
# 		@users[key] = new_value
# 		serialize_and_save
# 	end
# 
# 	[:each, :each_value, :each_key, :[]].each do |method|
# 		define_method method do |*args, &block|
# 			@users.send(method, *args, &block)
# 		end
# 	end
# end
