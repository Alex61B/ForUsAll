class CreateApprovals < ActiveRecord::Migration[8.1]
  def change
    create_table :approvals do |t|
      t.references :time_off_request, null: false, foreign_key: true, index: { unique: true }
      t.references :approver, null: false, foreign_key: { to_table: :users }
      t.integer :decision, null: false
      t.text :notes
      t.timestamps
    end
  end
end
