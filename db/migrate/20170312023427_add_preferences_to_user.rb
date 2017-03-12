require './constants'
require 'yaml'

class AddPreferencesToUser < ActiveRecord::Migration
  def change
    add_column :users, :preferences, :text, default: {
      campus: CONST::DEFAULT_CAMPUS,
      restaurant: CONST::DEFAULT_RESTAURANT
    }.to_yaml
  end
end
