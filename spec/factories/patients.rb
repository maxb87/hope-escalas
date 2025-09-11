FactoryBot.define do
  factory :patient do
    sequence(:full_name) { |n| "Paciente #{n}" }
    gender { "female" }
    birthday { Date.new(1990, 1, 1) }
    started_at { Date.current }
    sequence(:email) { |n| "paciente#{n}@test.com" }
    sequence(:cpf) { |n| sprintf("%011d", n).chars.join }
    rg { "123456789" }
    current_address { "Endereço de teste" }
    current_phone { "(11) 99999-9999" }
    deleted_at { nil }
  end
end
