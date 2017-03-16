class CreateTicketsTable < ActiveRecord::Migration
  def change
    create_table :tickets do |t|
      t.belongs_to :user, foreign_key: true
      t.integer :chat_id, null: false, limit: 8
      t.integer :issue
      t.text :feedback
      t.boolean :solved
    end
  end
end
