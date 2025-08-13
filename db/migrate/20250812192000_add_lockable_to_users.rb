class AddLockableToUsers < ActiveRecord::Migration[8.0]
  def change
    unless column_exists?(:users, :failed_attempts)
      add_column :users, :failed_attempts, :integer, default: 0, null: false
    end

    unless column_exists?(:users, :unlock_token)
      add_column :users, :unlock_token, :string
      add_index  :users, :unlock_token, unique: true
    end

    unless column_exists?(:users, :locked_at)
      add_column :users, :locked_at, :datetime
    end
  end
end
