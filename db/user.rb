class User < ActiveRecord::Base
  serialize :preferences, Hash
  serialize :restaurants, Array
  has_many :schedules
end
