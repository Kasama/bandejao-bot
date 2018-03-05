require './utils/constants'
require './db/user.rb'
require 'yaml'

class MultipleRestaurants < ActiveRecord::Migration
  def up
    add_column :users, :restaurants, :text, default: [
      {
        campus: CONST::DEFAULT_CAMPUS,
        restaurant: CONST::DEFAULT_RESTAURANT,
        campus_alias: CONST::DEFAULT_CAMPUS_ALIAS,
        restaurant_alias: CONST::DEFAULT_RESTAURANT_ALIAS
      }
    ].to_yaml
    User.find_each do |user|
      user.restaurants = [user.preferences]
      user.save!
    end
  end

  def down
    remove_column :users, :restaurants
  end
end
