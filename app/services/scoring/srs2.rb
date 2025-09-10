# frozen_string_literal: true

module Scoring
  class Srs2
    # Calcula resultados padronizados para o SRS-2
    # answers: { "item_1"=>"1", "item_2"=>"3", ... }
    def self.calculate(answers, scale_version: "2.0")
      # Questões que devem ter valores invertidos (1->4, 2->3, 3->2, 4->1)
      inverted_items = [ 3, 7, 11, 12, 15, 17, 21, 22, 26, 32, 38, 40, 43, 45, 48, 52, 55 ]

      raw_score = answers.map do |key, value|
        item_num = key.match(/item_(\d+)/)[1].to_i
        raw_value = value.to_i

        # Aplicar inversão se necessário, depois converter para escala 0-3
        if inverted_items.include?(item_num)
          inverted_value = 5 - raw_value  # Inverte: 1->4, 2->3, 3->2, 4->1
          inverted_value - 1  # Converte para escala 0-3
        else
          raw_value - 1  # Converte diretamente para escala 0-3
        end
      end.sum

      # SRS-2 scoring ranges para 65 itens (escala 0-3 após conversão)
      # Pontuação máxima: 65 * 3 = 195
      # Pontuação mínima: 65 * 0 = 0
      level = case raw_score
      when 0..25 then "Normal"
      when 26..55 then "Leve"
      when 56..85 then "Moderado"
      when 86..195 then "Severo"
      else "Pontuação inválida"
      end

      # Calcular subescalas SRS-2 (baseado na estrutura real da escala)
      social_awareness = calculate_subscale_raw(answers, (1..13).to_a)
      social_cognition = calculate_subscale_raw(answers, (14..26).to_a)
      social_communication = calculate_subscale_raw(answers, (27..39).to_a)
      social_motivation = calculate_subscale_raw(answers, (40..52).to_a)
      repetitive_patterns = calculate_subscale_raw(answers, (53..65).to_a)
      social_interaction = calculate_subscale_raw(answers, (1..65).to_a)

      {
        "schema_version" => 1,
        "scale_code" => "SRS-2",
        "scale_version" => scale_version,
        "computed_at" => Time.current.iso8601,
        "metrics" => {
          "raw_score" => raw_score,
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

    def self.calculate_subscale_raw(answers, item_numbers)
      # Questões que devem ter valores invertidos
      inverted_items = [ 3, 7, 11, 12, 15, 17, 21, 22, 26, 32, 38, 40, 43, 45, 48, 52, 55 ]

      item_numbers.map do |num|
        raw_value = answers["item_#{num}"]&.to_i || 0

        # Aplicar inversão se necessário, depois converter para escala 0-3
        if inverted_items.include?(num)
          inverted_value = 5 - raw_value  # Inverte: 1->4, 2->3, 3->2, 4->1
          inverted_value - 1  # Converte para escala 0-3
        else
          raw_value - 1  # Converte diretamente para escala 0-3
        end
      end.sum
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
        "Interpretação não disponível."
      end
    end
  end
end
