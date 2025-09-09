FactoryBot.define do
  factory :psychometric_scale do
    name { "Escala de Responsividade Social - Segunda Edição" }
    code { "SRS-2" }
    description { "Escala para avaliar sintomas de transtornos do espectro autista" }
    version { "2.0" }
    is_active { true }

    trait :inactive do
      is_active { false }
    end

    trait :srs2 do
      name { "Escala de Responsividade Social - Segunda Edição" }
      code { "SRS-2" }
    end

    trait :srs2_self_report do
      name { "SRS-2 - Formulário de Autorrelato" }
      code { "SRS-2-SR" }
      description { "Formulário de autorrelato da Escala de Responsividade Social" }
    end

    trait :srs2_hetero_report do
      name { "SRS-2 - Formulário de Heterorrelato" }
      code { "SRS-2-HR" }
      description { "Formulário de heterorrelato da Escala de Responsividade Social" }
    end
  end
end
