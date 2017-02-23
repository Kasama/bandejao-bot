module Schema
  def create_users
    unless ActiveRecord::Base.connection.data_source_exists? :users
      ActiveRecord::Schema.define do
        create_table :users, id: false do |t|
          t.integer :id, null: false, index: true
          t.string :username, null: true, index: true
          t.string :first_name, null: true
          t.string :last_name, null: true
          t.timestamps null: false
        end
      end
    end
  end

  def create_schedules
    unless ActiveRecord::Base.connection.data_source_exists? :schedule
      ActiveRecord::Schema.define do
        create_table :schedule, id: false do |t|
          t.integer :id, null: false, index: true
          t.belongs_to :user, foreign_key: true
          t.string :cronwhen
        end
      end
    end
  end
end
