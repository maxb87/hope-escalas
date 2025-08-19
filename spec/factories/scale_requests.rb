FactoryBot.define do
  factory :scale_request do
    association :patient
    association :professional  
    association :psychometric_scale
    status { :pending }
    requested_at { Time.current }
    notes { "Observações da solicitação" }

    trait :pending do
      status { :pending }
    end

    trait :completed do
      status { :completed }
    end

    trait :cancelled do
      status { :cancelled }
    end

    trait :expired do
      status { :expired }
    end
  end
end
