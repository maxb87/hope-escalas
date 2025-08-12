class AddAccountToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :account, polymorphic: true, index: true
    add_column :users, :force_password_reset, :boolean, default: true, null: false
  end
end
