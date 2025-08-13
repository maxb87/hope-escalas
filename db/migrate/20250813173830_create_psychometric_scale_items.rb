class CreatePsychometricScaleItems < ActiveRecord::Migration[8.0]
  def change
    create_table :psychometric_scale_items do |t|
      t.references :psychometric_scale, null: false, foreign_key: true
      t.integer :item_number, null: false
      t.text :question_text, null: false
      t.jsonb :options, null: false, default: {}
      t.boolean :is_required, default: true
      t.timestamps
    end

    add_index :psychometric_scale_items, [ :psychometric_scale_id, :item_number ],
              unique: true, name: 'index_scale_items_on_scale_and_number'
    add_index :psychometric_scale_items, :options, using: :gin
  end
end
