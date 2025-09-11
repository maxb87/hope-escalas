class AddRelatorFieldsToScaleResponses < ActiveRecord::Migration[8.0]
  def change
    add_column :scale_responses, :relator_name, :string
    add_column :scale_responses, :relator_relationship, :string
  end
end
