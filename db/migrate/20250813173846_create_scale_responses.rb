class CreateScaleResponses < ActiveRecord::Migration[8.0]
  def change
    create_table :scale_responses do |t|
      t.references :scale_request, null: false, foreign_key: true
      t.references :patient, null: false, foreign_key: true
      t.references :psychometric_scale, null: false, foreign_key: true
      t.jsonb :answers, null: false, default: {}
      t.integer :total_score
      t.string :interpretation
      t.datetime :completed_at, null: false
      t.datetime :deleted_at
      t.timestamps
    end

    add_index :scale_responses, :deleted_at
    add_index :scale_responses, :answers, using: :gin
    add_index :scale_responses, :total_score
    add_index :scale_responses, :completed_at
  end
end
