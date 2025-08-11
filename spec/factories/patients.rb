FactoryBot.define do
  factory :patient do
    full_name { "MyString" }
    sex { 1 }
    birthday { "2025-08-11" }
    started_at { "2025-08-11" }
    birthplace { "MyString" }
    email { "MyString" }
    cpf { "MyString" }
    rg { "MyString" }
    current_address { 1 }
    current_phone { 1 }
    deleted_at { "2025-08-11 15:53:55" }
  end
end
