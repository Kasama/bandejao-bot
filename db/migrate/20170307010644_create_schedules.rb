class CreateSchedules < ActiveRecord::Migration
  def change
    create_table :schedules do |t|
      t.belongs_to :user, foreign_key: true
      t.integer :chat_id, null: false, limit: 8
      t.string :cronwhen
      t.string :command
    end
  end
end
