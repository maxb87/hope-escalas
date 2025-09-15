# frozen_string_literal: true

module Scoring
  class Srs2
    # Calcula resultados padronizados para o SRS-2
    # answers: { "item_1"=>"1", "item_2"=>"3", ... }
    # patient_gender: 'male' ou 'female'
    # patient_age: idade em anos
    # scale_type: 'self_report' ou 'parent_report'
    def self.calculate(answers, scale_version: "2.0", patient_gender: nil, patient_age: nil, scale_type: nil)
      raw_score = calculate_raw_score(answers)
      level = determine_interpretation_level(raw_score)
      subscale_scores = calculate_subscale_scores(answers)
      lookup_results = calculate_lookup_results(raw_score, subscale_scores, patient_gender, patient_age, scale_type)

      build_result_hash(raw_score, level, subscale_scores, lookup_results, scale_version)
    end

    private

    # Calcula o raw score total aplicando inversões necessárias
    def self.calculate_raw_score(answers)
      inverted_items = [ 3, 7, 11, 12, 15, 17, 21, 22, 26, 32, 38, 40, 43, 45, 48, 52, 55 ]

      answers.map do |key, value|
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
    end

    # Determina o nível de interpretação baseado no raw score
    def self.determine_interpretation_level(raw_score)
      case raw_score
      when 0..25 then "Normal"
      when 26..55 then "Leve"
      when 56..85 then "Moderado"
      when 86..195 then "Severo"
      else "Pontuação inválida"
      end
    end

    # Calcula os raw scores de todas as subescalas
    def self.calculate_subscale_scores(answers)
      {
        social_awareness: calculate_subscale_raw(answers, [ 2, 7, 25, 32, 45, 52, 54, 56 ]),
        social_cognition: calculate_subscale_raw(answers, [ 5, 10, 15, 17, 30, 40, 42, 44, 48, 58, 59, 62 ]),
        social_communication: calculate_subscale_raw(answers, [ 12, 13, 16, 18, 19, 21, 22, 26, 33, 35, 36, 37, 38, 41, 46, 47, 51, 53, 55, 57, 60, 61 ]),
        social_motivation: calculate_subscale_raw(answers, [ 1, 3, 6, 9, 11, 23, 27, 34, 43, 64, 65 ]),
        restricted_interests: calculate_subscale_raw(answers, [ 4, 8, 14, 20, 24, 28, 29, 31, 39, 49, 50, 63 ]),
        social_interaction: calculate_subscale_raw(answers, [ 1, 2, 3, 5, 6, 7, 9, 10, 11, 12, 13, 15, 16, 17, 18, 19, 21, 22, 23, 25, 26, 27, 30, 32, 33, 34, 35, 36, 37, 38, 40, 41, 42, 43, 44, 45, 46, 47, 48, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65 ])
      }
    end

    # Calcula t-scores e percentis usando o lookup service
    def self.calculate_lookup_results(raw_score, subscale_scores, patient_gender, patient_age, scale_type)
      return empty_lookup_results unless patient_gender && patient_age && scale_type

      {
        total: calculate_total_lookup(raw_score, patient_gender, patient_age, scale_type),
        subscales: calculate_subscale_lookups(subscale_scores, patient_gender, patient_age, scale_type)
      }
    end

    # Calcula lookup para o score total
    def self.calculate_total_lookup(raw_score, patient_gender, patient_age, scale_type)
      {
        t_score: Srs2LookupService.lookup_total_t_score(
          raw_score,
          gender: patient_gender,
          age: patient_age,
          scale_type: scale_type
        ),
        percentile: Srs2LookupService.lookup_total_percentile(
          raw_score,
          gender: patient_gender,
          age: patient_age,
          scale_type: scale_type
        )
      }
    end

    # Calcula lookups para todas as subescalas
    def self.calculate_subscale_lookups(subscale_scores, patient_gender, patient_age, scale_type)
      subscale_mapping = {
        social_awareness: "social_awareness",
        social_cognition: "social_cognition",
        social_communication: "social_communication",
        social_motivation: "social_motivation",
        restricted_interests: "repetitive_patterns",
        social_interaction: "social_interaction"
      }

      subscale_scores.transform_values do |raw_score|
        subscale_name = subscale_mapping[subscale_scores.key(raw_score)]
        {
          raw_score: raw_score,
          t_score: Srs2LookupService.lookup_subscale_t_score(
            raw_score,
            subscale: subscale_name,
            gender: patient_gender,
            age: patient_age,
            scale_type: scale_type
          ),
          percentile: Srs2LookupService.lookup_subscale_percentile(
            raw_score,
            subscale: subscale_name,
            gender: patient_gender,
            age: patient_age,
            scale_type: scale_type
          )
        }
      end
    end

    # Retorna estrutura vazia para lookups quando dados do paciente não estão disponíveis
    def self.empty_lookup_results
      {
        total: { t_score: nil, percentile: nil },
        subscales: {
          social_awareness: { raw_score: nil, t_score: nil, percentile: nil },
          social_cognition: { raw_score: nil, t_score: nil, percentile: nil },
          social_communication: { raw_score: nil, t_score: nil, percentile: nil },
          social_motivation: { raw_score: nil, t_score: nil, percentile: nil },
          restricted_interests: { raw_score: nil, t_score: nil, percentile: nil },
          social_interaction: { raw_score: nil, t_score: nil, percentile: nil }
        }
      }
    end

    # Constrói o hash de resultado final
    def self.build_result_hash(raw_score, level, subscale_scores, lookup_results, scale_version)
      {
        "schema_version" => 1,
        "scale_code" => "SRS-2",
        "scale_version" => scale_version,
        "computed_at" => Time.current.iso8601,
        "metrics" => build_metrics_hash(raw_score, level, lookup_results[:total]),
        "subscales" => build_subscales_hash(subscale_scores, lookup_results[:subscales]),
        "interpretation" => build_interpretation_hash(level)
      }
    end

    # Constrói o hash de métricas principais
    def self.build_metrics_hash(raw_score, level, total_lookup)
      {
        "raw_score" => raw_score,
        "t_score" => total_lookup[:t_score],
        "percentile" => total_lookup[:percentile],
        "level" => level
      }
    end

    # Constrói o hash de subescalas
    def self.build_subscales_hash(subscale_scores, subscale_lookups)
      subscale_configs = {
        social_awareness: {
          description: "Percepção Social",
          items: [ 2, 7, 25, 32, 45, 52, 54, 56 ]
        },
        social_cognition: {
          description: "Cognição Social",
          items: [ 5, 10, 15, 17, 30, 40, 42, 44, 48, 58, 59, 62 ]
        },
        social_communication: {
          description: "Comunicação Social",
          items: [ 12, 13, 16, 18, 19, 21, 22, 26, 33, 35, 36, 37, 38, 41, 46, 47, 51, 53, 55, 57, 60, 61 ]
        },
        social_motivation: {
          description: "Motivação Social",
          items: [ 1, 3, 6, 9, 11, 23, 27, 34, 43, 64, 65 ]
        },
        restricted_interests: {
          description: "Interesses Restritos e Comportamentos Repetitivos",
          items: [ 4, 8, 14, 20, 24, 28, 29, 31, 39, 49, 50, 63 ]
        },
        social_interaction: {
          description: "Interação Social",
          items: [ 1, 2, 3, 5, 6, 7, 9, 10, 11, 12, 13, 15, 16, 17, 18, 19, 21, 22, 23, 25, 26, 27, 30, 32, 33, 34, 35, 36, 37, 38, 40, 41, 42, 43, 44, 45, 46, 47, 48, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65 ]
        }
      }

      subscale_scores.transform_keys(&:to_s).transform_values.with_index do |raw_score, index|
        subscale_key = subscale_scores.keys[index]
        config = subscale_configs[subscale_key]
        lookup = subscale_lookups[subscale_key]

        {
          "raw_score" => raw_score,
          "t_score" => lookup[:t_score],
          "percentile" => lookup[:percentile],
          "description" => config[:description],
          "items" => config[:items]
        }
      end
    end

    # Constrói o hash de interpretação
    def self.build_interpretation_hash(level)
      {
        "level" => level,
        "rules" => "SRS-2 v2.0 cutoffs (65 itens, escala 1-4)",
        "description" => get_interpretation_description(level),
        "total_range" => "65-260",
        "items_count" => 65
      }
    end

    # Calcula raw score de uma subescala específica
    def self.calculate_subscale_raw(answers, item_numbers)
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

    # Retorna descrição da interpretação baseada no nível
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
