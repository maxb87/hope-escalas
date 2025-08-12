class AddForcePasswordResetToUsers < ActiveRecord::Migration[8.0]
  def up
    unless column_exists?(:users, :force_password_reset)
      add_column :users, :force_password_reset, :boolean, default: true, null: false
    end
  end

  def down
    if column_exists?(:users, :force_password_reset)
      remove_column :users, :force_password_reset
    end
  end
end
