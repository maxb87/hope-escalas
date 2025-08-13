class CreateScaleRequests < ActiveRecord::Migration[8.0]
  def change
    create_table :scale_requests do |t|
      t.references :patient, null: false, foreign_key: true
      t.references :professional, null: false, foreign_key: true
      t.references :psychometric_scale, null: false, foreign_key: true
      t.integer :status, default: 0
      t.datetime :requested_at, null: false
      t.datetime :expires_at
      t.text :notes
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :scale_requests, :status
    add_index :scale_requests, :deleted_at
    add_index :scale_requests, :requested_at
    add_index :scale_requests, :expires_at
  end
end
