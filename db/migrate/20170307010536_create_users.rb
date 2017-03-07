class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users, id: false do |t|
      t.integer :id, null: false, index: true, primary_key: true
      t.string :username, null: true, index: true
      t.string :first_name, null: true
      t.string :last_name, null: true
      t.timestamps null: false
    end
  end
end
