# frozen_string_literal: true

module Scoring
  class BDI
    # Calcula resultados padronizados para o BDI
    # answers: { "item_1"=>"0", "item_2"=>"3", ... }
    def self.calculate(answers, scale_version: "1.0")
      total = answers.values.map { |v| v.to_i }.sum

      level = case total
      when 0..11 then "Mínima"
      when 12..19 then "Leve"
      when 20..27 then "Moderada"
      else "Grave"
      end

      {
        "schema_version" => 1,
        "scale_code" => "BDI",
        "scale_version" => scale_version,
        "computed_at" => Time.current.iso8601,
        "metrics" => { "total" => total },
        "subscales" => {},
        "interpretation" => { "level" => level, "rules" => "BDI v1 cutoffs" }
      }
    end
  end
end
