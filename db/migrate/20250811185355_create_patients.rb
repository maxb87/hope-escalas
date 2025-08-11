class CreatePatients < ActiveRecord::Migration[8.0]
  def change
    create_table :patients do |t|
      t.string :full_name, null: false
      t.integer :sex
      t.date :birthday, null: false
      t.date :started_at
      t.string :email, null: false
      t.string :cpf, null: false
      t.string :rg
      t.integer :current_phone
      t.integer :current_address
      t.datetime :deleted_at

      t.timestamps
    end
    add_index :patients, :deleted_at
    add_index :patients, :cpf, unique: true

    # DB constraints for data quality
    # CPF: exactly 11 numeric digits
    add_check_constraint :patients, "char_length(cpf) = 11 AND cpf ~ '^[0-9]{11}$'", name: "patients_cpf_format"
    # email: basic RFC-like pattern (case-insensitive)
    add_check_constraint :patients, "email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,}$'", name: "patients_email_format"
    # full_name: minimum length 5
    add_check_constraint :patients, "char_length(full_name) >= 5", name: "patients_full_name_minlen"
  end
end
