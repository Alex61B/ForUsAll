class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false, limit: 255, default: ""
      t.string :encrypted_password, null: false, default: ""
      t.string :first_name, null: false, limit: 100
      t.string :last_name, null: false, limit: 100
      t.integer :role, null: false, default: 0
      t.references :department, null: true, foreign_key: true
      t.references :manager, null: true, foreign_key: { to_table: :users }
      t.string :reset_password_token
      t.datetime :reset_password_sent_at
      t.datetime :remember_created_at
      t.timestamps
    end
    add_index :users, :email, unique: true
    add_index :users, :reset_password_token, unique: true
    add_index :users, :role
  end
end
