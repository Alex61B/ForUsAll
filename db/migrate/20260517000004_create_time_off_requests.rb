class CreateTimeOffRequests < ActiveRecord::Migration[8.1]
  def change
    create_table :time_off_requests do |t|
      t.references :user, null: false, foreign_key: true
      t.integer :leave_type, null: false
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.text :reason
      t.integer :status, null: false, default: 0
      t.references :reviewed_by, null: true, foreign_key: { to_table: :users }
      t.datetime :reviewed_at
      t.timestamps
    end
    add_index :time_off_requests, [ :user_id, :status ]
    add_index :time_off_requests, [ :user_id, :leave_type, :status ]
  end
end
