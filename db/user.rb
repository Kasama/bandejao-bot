class User < ActiveRecord::Base
  serialize :preferences, Hash
  has_many :schedules
  has_many :tickets
end
