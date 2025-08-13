class CreatePsychometricScales < ActiveRecord::Migration[8.0]
  def change
    create_table :psychometric_scales do |t|
      t.string :name, null: false
      t.string :code, null: false
      t.text :description
      t.string :version
      t.boolean :is_active, default: true
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :psychometric_scales, :code, unique: true
    add_index :psychometric_scales, :deleted_at
    add_index :psychometric_scales, :is_active
  end
end
