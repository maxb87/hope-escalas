json.extract! patient, :id, :full_name, :sex, :birthday, :started_at, :birthplace, :email, :cpf, :rg, :current_address, :current_phone, :deleted_at, :created_at, :updated_at
json.url patient_url(patient, format: :json)
