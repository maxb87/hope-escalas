class AddExtraToPsychometricScaleItems < ActiveRecord::Migration[8.0]
  def change
    add_column :psychometric_scale_items, :extra, :jsonb, default: {}, null: false
    add_index :psychometric_scale_items, :extra, using: :gin
  end
end
