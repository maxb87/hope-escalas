class CreateProfessionals < ActiveRecord::Migration[8.0]
  def change
    create_table :professionals do |t|
      t.string :full_name, null: false
      t.integer :sex
      t.date :birthday, null: false
      t.date :started_at
      t.string :email, null: false
      t.string :cpf, null: false
      t.string :rg
      t.integer :current_phone
      t.integer :current_address
      t.string :professional_id
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :professionals, :deleted_at
    add_index :professionals, :cpf, unique: true
    add_index :professionals, :email, unique: true

    # DB constraints for data quality
    # CPF: exactly 11 numeric digits
    add_check_constraint :professionals, "char_length(cpf) = 11 AND cpf ~ '^[0-9]{11}$'", name: "professionals_cpf_format"
    # email: basic RFC-like pattern (case-insensitive)
    add_check_constraint :professionals, "email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'", name: "professionals_email_format"
    # full_name: minimum length 5 (validations complement at model level if needed)
    add_check_constraint :professionals, "char_length(full_name) >= 5", name: "professionals_full_name_minlen"
  end
end
