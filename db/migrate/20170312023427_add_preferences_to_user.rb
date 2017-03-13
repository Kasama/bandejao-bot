require './constants'
require 'yaml'

class AddPreferencesToUser < ActiveRecord::Migration
  def change
    add_column :users, :preferences, :text, default: {
      campus: CONST::DEFAULT_CAMPUS,
      restaurant: CONST::DEFAULT_RESTAURANT,
      campus_alias: CONST::DEFAULT_CAMPUS_ALIAS,
      restaurant_alias: CONST::DEFAULT_RESTAURANT_ALIAS
    }.to_yaml
  end
end
