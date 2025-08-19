FactoryBot.define do
  factory :professional do
    sequence(:full_name) { |n| "Dr. Profissional #{n}" }
    sex { 0 }
    birthday { Date.new(1980, 1, 1) }
    started_at { Date.current }
    sequence(:email) { |n| "profissional#{n}@test.com" }
    sequence(:cpf) { |n| sprintf("%011d", 100000 + n).chars.join }
    rg { "987654321" }
    current_address { "Endereço profissional" }
    current_phone { "(11) 88888-8888" }
    sequence(:professional_id) { |n| "CRM#{n}" }
    deleted_at { nil }
  end
end
