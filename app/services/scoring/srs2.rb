# frozen_string_literal: true

module Scoring
  class Srs2
    # Calcula resultados padronizados para o SRS-2
    # answers: { "item_1"=>"1", "item_2"=>"3", ... }
    # patient_gender: 'male' ou 'female'
    # patient_age: idade em anos
    # scale_type: 'self_report' ou 'parent_report'
    def self.calculate(answers, scale_version: "2.0", patient_gender: nil, patient_age: nil, scale_type: nil, patient: nil)
      # Armazenar o paciente em uma variável de classe para uso nas interpretações
      @patient = patient

      raw_score = calculate_raw_score(answers)
      subscale_scores = calculate_subscale_scores(answers)
      lookup_results = calculate_lookup_results(raw_score, subscale_scores, patient_gender, patient_age, scale_type)

      # Use t-score for interpretation level determination
      t_score = lookup_results[:total][:t_score]
      level = determine_interpretation_level(t_score)

      build_result_hash(raw_score, level, subscale_scores, lookup_results, scale_version, patient)
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

    # Determina o nível de interpretação baseado no t-score
    def self.determine_interpretation_level(t_score)
      return "Pontuação inválida" unless t_score

      case t_score
      when 0..54 then "normal"
      when 55..64 then "leve"
      when 65..74 then "moderado"
      when 75..100 then "severo"
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
    def self.build_result_hash(raw_score, level, subscale_scores, lookup_results, scale_version, patient = nil)
      {
        "schema_version" => 1,
        "scale_code" => "SRS-2",
        "scale_version" => scale_version,
        "computed_at" => Time.current.iso8601,
        "metrics" => build_metrics_hash(raw_score, level, lookup_results[:total]),
        "subscales" => build_subscales_hash(subscale_scores, lookup_results[:subscales], patient),
        "interpretation" => build_interpretation_hash(level)
      }
    end

    # Constrói o hash de métricas principais
    def self.build_metrics_hash(raw_score, level, total_lookup)
      {
        "raw_score" => raw_score,
        "t_score" => total_lookup[:t_score],
        "percentile" => total_lookup[:percentile],
        "level" => level,
        "level_plural" => level_pluralize(level)
      }
    end

    # Constrói o hash de subescalas
    def self.build_subscales_hash(subscale_scores, subscale_lookups, patient = nil)
      subscale_configs = {
        social_awareness: {
          title: "Percepção Social",
          raw_score: subscale_scores[:social_awareness],
          t_score: subscale_lookups[:social_awareness][:t_score],
          percentile: subscale_lookups[:social_awareness][:percentile],
          level: determine_subscale_level(subscale_lookups[:social_awareness][:t_score]),
          description: "captar pistas sociais básicas e compreender aspectos perceptivos do comportamento recíproco.",
          interpretation: get_subscale_interpretation("social_awareness", subscale_lookups[:social_awareness][:t_score], patient),
          items: [ 2, 7, 25, 32, 45, 52, 54, 56 ]
        },
        social_cognition: {
          title: "Cognição Social",
          raw_score: subscale_scores[:social_cognition],
          t_score: subscale_lookups[:social_cognition][:t_score],
          percentile: subscale_lookups[:social_cognition][:percentile],
          level: determine_subscale_level(subscale_lookups[:social_cognition][:t_score]),
          description: "capacidade de processar informações sociais, lidando com o aspecto cognitivo do comportamento social.",
          interpretation: get_subscale_interpretation("social_cognition", subscale_lookups[:social_cognition][:t_score], patient),
          items: [ 5, 10, 15, 17, 30, 40, 42, 44, 48, 58, 59, 62 ]
        },
        social_communication: {
          title: "Comunicação Social",
          raw_score: subscale_scores[:social_communication],
          t_score: subscale_lookups[:social_communication][:t_score],
          percentile: subscale_lookups[:social_communication][:percentile],
          level: determine_subscale_level(subscale_lookups[:social_communication][:t_score]),
          description: "comunicação expressiva, lidando com os aspectos motores do comportamento social recíproco",
          interpretation: get_subscale_interpretation("social_communication", subscale_lookups[:social_communication][:t_score], patient),
          items: [ 12, 13, 16, 18, 19, 21, 22, 26, 33, 35, 36, 37, 38, 41, 46, 47, 51, 53, 55, 57, 60, 61 ]
        },
        social_motivation: {
          title: "Motivação Social",
          raw_score: subscale_scores[:social_motivation],
          t_score: subscale_lookups[:social_motivation][:t_score],
          percentile: subscale_lookups[:social_motivation][:percentile],
          level: determine_subscale_level(subscale_lookups[:social_motivation][:t_score]),
          description: "interesse e capacidade de engajar-se em comportamentos sociais e interpessoais",
          interpretation: get_subscale_interpretation("social_motivation", subscale_lookups[:social_motivation][:t_score], patient),
          items: [ 1, 3, 6, 9, 11, 23, 27, 34, 43, 64, 65 ]
        },
        restricted_interests: {
          title: "Interesses Restritos e Comportamentos Repetitivos",
          raw_score: subscale_scores[:restricted_interests],
          t_score: subscale_lookups[:restricted_interests][:t_score],
          percentile: subscale_lookups[:restricted_interests][:percentile],
          level: determine_subscale_level(subscale_lookups[:restricted_interests][:t_score]),
          description: "comportamentos estereotipados, interesses restritos ou fixações (como foco excessivo em temas específicos ou insistência em rotinas).",
          interpretation: get_subscale_interpretation("restricted_interests", subscale_lookups[:restricted_interests][:t_score], patient),
          items: [ 4, 8, 14, 20, 24, 28, 29, 31, 39, 49, 50, 63 ]
        },
        social_interaction: {
          title: "Interação Social Global",
          raw_score: subscale_scores[:social_interaction],
          t_score: subscale_lookups[:social_interaction][:t_score],
          percentile: subscale_lookups[:social_interaction][:percentile],
          level: determine_subscale_level(subscale_lookups[:social_interaction][:t_score]),
          description: "reconhecimento e interpretação de sinais sociais, bem como motivação para o contato interpessoal social expressivo.",
          interpretation: get_subscale_interpretation("social_interaction", subscale_lookups[:social_interaction][:t_score], patient),
          items: [ 1, 2, 3, 5, 6, 7, 9, 10, 11, 12, 13, 15, 16, 17, 18, 19, 21, 22, 23, 25, 26, 27, 30, 32, 33, 34, 35, 36, 37, 38, 40, 41, 42, 43, 44, 45, 46, 47, 48, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, 61, 62, 63, 64, 65 ]
        }
      }

      subscale_scores.transform_keys(&:to_s).transform_values.with_index do |raw_score, index|
        subscale_key = subscale_scores.keys[index]
        config = subscale_configs[subscale_key]
        lookup = subscale_lookups[subscale_key]

        {
          "title" => config[:title],
          "raw_score" => raw_score,
          "t_score" => lookup[:t_score],
          "percentile" => lookup[:percentile],
          "level" => config[:level],
          "description" => config[:description],
          "interpretation" => config[:interpretation],
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
      when "normal"
        "Normal"
      when "leve"
        "Prejuízo Leve"
      when "moderado"
        "Prejuízo Moderado"
      when "severo"
        "Prejuízo Severo"
      else
        "Interpretação não disponível."
      end
    end

    def self.get_subscale_interpretation(subscale_name, t_score, patient = nil)
      level = determine_subscale_level(t_score)

      case subscale_name
      when "social_awareness"
        case level
        when "normal" then "#{patient&.first_name&.titleize } não apresenta, de acordo com seu entendimento, dificuldades em percepção social, ou seja, considera-se capaz de captar pistas sociais básicas e compreender aspectos perceptivos do comportamento recíproco."
        when "leve" then "#{patient&.first_name&.titleize } percebe que possui dificuldades na interpretação de pistas sociais ou aspectos perceptivos do comportamento recíproco."
        when "moderado" then "#{patient&.first_name&.titleize } reconhece dificuldades importantes na interpretação de pistas sociais e aspectos perceptivos do comportamento recíproco."
        when "severo" then "#{patient&.first_name&.titleize } reconhece dificuldades graves e limitações significativas que impactam severamente a compreensão de pistas sociais e aspectos perceptivos do comportamento recíproco."
        else "Interpretação não disponível."
        end
      when "social_cognition"
        case level
        when "normal" then "#{patient&.first_name&.titleize } não percebe dificuldades na compreensão de nuances do comportamento alheio, o que minimiza possíveis mal-entendidos ou interpretações literais."
        when "leve" then "#{patient&.first_name&.titleize } percebe que possui dificuldades para compreender nuances do comportamento alheio, o que pode levar a mal-entendidos ou interpretações literais."
        when "moderado" then "#{patient&.first_name&.titleize } reconhece dificuldades importantes para compreender nuances do comportamento alheio, o que pode levar a mal-entendidos, dificuldades de comunicação ou interpretações literais."
        when "severo" then "#{patient&.first_name&.titleize } reconhece dificuldades graves e limitações significativas que impactam severamente a compreensão de nuances do comportamento alheio, o que pode causar mal-entendidos, interpretações literais e a poissibilidade de impacto funcional no fluxo de comunicação."
        else "Interpretação não disponível."
        end
      when "social_communication"
        case level
        when "normal" then "#{patient&.gender == 'male' ? 'Ele' : 'Ela'} não percebe dificuldades significativas em sua comunicação social, considera-se capaz de expressar idéias, sentimentos ou respostas sociais."
        when "leve" then "#{patient&.gender == 'male' ? 'Ele' : 'Ela'} percebe prejuízo leve na fluência da comunicação social, na expressäo adequada de idéias, sentimentos e respostas sociais."
        when "moderado" then "#{patient&.gender == 'male' ? 'Ele' : 'Ela'} reconhece prejuízos na fluência comunicativa, especialmente na expressão adequada de idéias, de sentimentos e nas respostas sociais."
        when "severo" then "#{patient&.gender == 'male' ? 'Ele' : 'Ela'} relata graves dificuldades na fluência de sua comunicação social, especialmente na expressão adequada de idéias, ou de seus sentimentos e respostas sociais."
        else "Interpretação não disponível."
        end
      when "social_motivation"
        case level
        when "normal" then "#{patient&.gender == 'male' ? 'O' : 'A'} paciente não relata inibição ou desinteresse para interações espontâneas, considera-se #{patient&.gender == 'male' ? 'motivado' : 'motivada'} a realizar interações sociais e interpessoais."
        when "leve" then "#{patient&.gender == 'male' ? 'O' : 'A'} paciente relata inibição leve para interações espontâneas, o que pode se manifestar como retraimento, desconforto em grupos ou evitamento de situações sociais."
        when "moderado" then "#{patient&.gender == 'male' ? 'O' : 'A'} paciente relata inibição moderada para interações espontâneas, o que pode se manifestar como retraimento, desconforto em grupos ou evitamento de situações sociais."
        when "severo" then "#{patient&.gender == 'male' ? 'O' : 'A'} paciente relata graves dificuldades para interações espontâneas, manifestando-se como retraimento, desconforto em grupos e evitamento de situações sociais."
        else "Interpretação não disponível."
        end
      when "restricted_interests"
        case level
        when "normal" then "#{patient&.first_name&.titleize } não apresenta, de acordo com sua percepção, traços associados a padrões de comportamento estereotipado, interesses restritos ou fixações."
        when "leve" then "#{patient&.first_name&.titleize } reconhece traços compatíveis com este padrão, com prejuízo leve em sua rotina, hábitos e interesses"
        when "moderado" then "#{patient&.first_name&.titleize } reconhece traços compatíveis com este padrão, com prejuízo moderado em sua rotina, hábitos e ações ligadas a seus interesses"
        when "severo" then "#{patient&.first_name&.titleize } reconhece traços compatíveis com este padrão, com prejuízo severo e limitações em sua rotina com relação a hábitos e fixações"
        else "Interpretação não disponível."
        end
      when "social_interaction"
        case level
        when "normal" then "A soma dos domínios comprometidos sugere comportamento normal ou de baixa necessidade de adaptação em sua capacidade de estabelecer e sustentar trocas interpessoais de maneira funcional."
        when "leve" then "A soma dos domínios comprometidos indica prejuízo leve em sua capacidade de estabelecer e sustentar trocas interpessoais de maneira funcional."
        when "moderado" then "A soma dos domínios comprometidos indica prejuízo moderado e dificuldades em sua capacidade de estabelecer e sustentar trocas interpessoais de maneira funcional"
        when "severo" then "A soma dos domínios comprometidos aponta prejuízo severo e dificuldades significativas em sua capacidade de estabelecer e sustentar trocas interpessoais de maneira funcional"
        else "Interpretação não disponível."
        end
      end
    end

    # Determina o nível de interpretação para subescalas baseado no t-score
    def self.determine_subscale_level(t_score)
      return "Pontuação inválida" unless t_score

      case t_score
      when 0..54 then "normal"
      when 55..64 then "leve"
      when 65..74 then "moderado"
      when 75..100 then "severo"
      else "Pontuação inválida"
      end
    end

    def self.level_pluralize(level)
      case level
      when "normal" then "prejuízos de baixa significância clínica"
      when "leve" then "prejuízos leves"
      when "moderado" then "prejuízos moderados"
      when "severo" then "prejuízos severos"
      else "Interpretação não disponível."
      end
    end

    # Retorna interpretação específica para cada subescala
  end
end
