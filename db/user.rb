class User < ActiveRecord::Base
  has_many :schedules
end
