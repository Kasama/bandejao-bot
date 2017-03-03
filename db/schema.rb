require './db/user'
require './db/schedule'

module Schema
  module_function

  def create_users
    unless ActiveRecord::Base.connection.data_source_exists? :users
      ActiveRecord::Schema.define do
        create_table :users, id: false do |t|
          t.integer :id, null: false, index: true, primary_key: true
          t.string :username, null: true, index: true
          t.string :first_name, null: true
          t.string :last_name, null: true
          t.timestamps null: false
        end
      end
    end
  end

  def create_schedules
    unless ActiveRecord::Base.connection.data_source_exists? :schedules
      ActiveRecord::Schema.define do
        create_table :schedules do |t|
          t.belongs_to :user, foreign_key: true
          t.integer :chat_id, null: false, limit: 8
          t.string :cronwhen
          t.string :command
        end
      end
    end
  end
end
