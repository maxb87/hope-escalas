FactoryBot.define do
  factory :psychometric_scale do
    name { "Inventário de Depressão de Beck" }
    code { "BDI" }
    description { "Escala de 21 itens para avaliar sintomas de depressão" }
    version { "1.0" }
    is_active { true }

    trait :inactive do
      is_active { false }
    end

    trait :bdi do
      name { "Inventário de Depressão de Beck" }
      code { "BDI" }
    end

    trait :bai do
      name { "Inventário de Ansiedade de Beck" }
      code { "BAI" }
      description { "Escala de 21 itens para avaliar sintomas de ansiedade" }
    end
  end
end
