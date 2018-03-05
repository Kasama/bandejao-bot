class User < ActiveRecord::Base
  serialize :preferences, Hash
  has_many :schedules
end
