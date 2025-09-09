# frozen_string_literal: true

module Scoring
  class Srs2
    # Calcula resultados padronizados para o SRS-2
    # answers: { "item_1"=>"1", "item_2"=>"3", ... }
    def self.calculate(answers, scale_version: "2.0")
      total = answers.values.map { |v| v.to_i }.sum
      
      # SRS-2 scoring ranges para 65 itens (escala 1-4)
      # Pontuação máxima: 65 * 4 = 260
      # Pontuação mínima: 65 * 1 = 65
      level = case total
      when 65..90 then "Normal"
      when 91..120 then "Leve"
      when 121..150 then "Moderado"
      when 151..260 then "Severo"
      else "Pontuação inválida"
      end

      # Calcular subescalas SRS-2 (baseado na estrutura real da escala)
      social_awareness = calculate_subscale(answers, (1..13).to_a)
      social_cognition = calculate_subscale(answers, (14..26).to_a)
      social_communication = calculate_subscale(answers, (27..39).to_a)
      social_motivation = calculate_subscale(answers, (40..52).to_a)
      restricted_interests = calculate_subscale(answers, (53..65).to_a)

      {
        "schema_version" => 1,
        "scale_code" => "SRS-2",
        "scale_version" => scale_version,
        "computed_at" => Time.current.iso8601,
        "metrics" => { 
          "total" => total,
          "social_awareness" => social_awareness,
          "social_cognition" => social_cognition,
          "social_communication" => social_communication,
          "social_motivation" => social_motivation,
          "restricted_interests" => restricted_interests
        },
        "subscales" => {
          "social_awareness" => { 
            "score" => social_awareness, 
            "description" => "Consciência Social",
            "items" => "1-13"
          },
          "social_cognition" => { 
            "score" => social_cognition, 
            "description" => "Cognição Social",
            "items" => "14-26"
          },
          "social_communication" => { 
            "score" => social_communication, 
            "description" => "Comunicação Social",
            "items" => "27-39"
          },
          "social_motivation" => { 
            "score" => social_motivation, 
            "description" => "Motivação Social",
            "items" => "40-52"
          },
          "restricted_interests" => { 
            "score" => restricted_interests, 
            "description" => "Interesses Restritos e Comportamentos Repetitivos",
            "items" => "53-65"
          }
        },
        "interpretation" => { 
          "level" => level, 
          "rules" => "SRS-2 v2.0 cutoffs (65 itens, escala 1-4)",
          "description" => get_interpretation_description(level),
          "total_range" => "65-260",
          "items_count" => 65
        }
      }
    end

    private

    def self.calculate_subscale(answers, item_numbers)
      item_numbers.map { |num| answers["item_#{num}"]&.to_i || 0 }.sum
    end

    def self.get_interpretation_description(level)
      case level
      when "Normal"
        "Funcionamento social dentro da faixa normal. Habilidades sociais adequadas para a idade."
      when "Leve"
        "Dificuldades leves em habilidades sociais. Pode apresentar algumas limitações sociais sutis."
      when "Moderado"
        "Dificuldades moderadas em habilidades sociais. Limitações sociais mais evidentes que podem impactar o funcionamento."
      when "Severo"
        "Dificuldades severas em habilidades sociais. Limitações significativas que impactam substancialmente o funcionamento social."
      else
        "Interpretação não disponível para esta pontuação."
      end
    end
  end
end
