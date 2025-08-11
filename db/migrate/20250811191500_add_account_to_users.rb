class AddAccountToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :account, polymorphic: true, index: true
  end
end

