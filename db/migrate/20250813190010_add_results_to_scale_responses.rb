class AddResultsToScaleResponses < ActiveRecord::Migration[8.0]
  def change
    add_column :scale_responses, :results, :jsonb, default: {}, null: false
    add_column :scale_responses, :results_schema_version, :integer, default: 1, null: false
    add_column :scale_responses, :computed_at, :datetime

    add_index :scale_responses, :results, using: :gin unless index_exists?(:scale_responses, :results)
    add_index :scale_responses, :answers, using: :gin unless index_exists?(:scale_responses, :answers)
  end
end
