# frozen_string_literal: true

module Scoring
  class Psa
    # Calcula resultados para o PSA - Perfil Sensorial do Adulto/Adolescente
    # answers: { "item_1"=>"1", "item_2"=>"3", ... }
    def self.calculate(answers, scale_version: "1.0", patient_gender: nil, patient_age: nil, patient: nil)
      # Armazenar o paciente em uma variável de classe para uso nos métodos
      @patient = patient
      @patient_age = patient_age || calculate_patient_age(patient)
      
      # Calcular scores por categoria
      category_scores = calculate_category_scores(answers)
      
      # Calcular scores por subescala
      subscale_scores = calculate_subscale_scores(answers)
      
      # Determinar níveis por categoria
      category_levels = determine_category_levels(category_scores)
      
      # Calcular score total
      total_score = category_scores.values.sum
      
      # Determinar nível geral
      overall_level = determine_overall_level(total_score)
      
      build_result_hash(total_score, category_scores, subscale_scores, category_levels, overall_level, scale_version)
    end

    private

    # Calcula scores para cada categoria PSA
    def self.calculate_category_scores(answers)
      {
        'baixo_registro' => calculate_category_raw(answers, [3,6,12,15,21,23,36,37,39,41,44,45,52,55,59]),
        'procura_sensacao' => calculate_category_raw(answers, [2,4,8,10,14,17,19,28,30,32,40,42,47,50,58]),
        'sensibilidade_sensorial' => calculate_category_raw(answers, [7,9,13,16,20,22,25,27,31,33,34,48,51,54,60]),
        'evita_sensacao' => calculate_category_raw(answers, [1,5,11,18,24,26,29,35,38,43,46,49,53,56,57])
      }
    end

    # Calcula scores para cada subescala PSA
    def self.calculate_subscale_scores(answers)
      {
        'A' => calculate_subscale_raw(answers, (1..8).to_a),      # Processamento Tátil/Olfativo
        'B' => calculate_subscale_raw(answers, (9..16).to_a),     # Processamento Vestibular/Proprioceptivo
        'C' => calculate_subscale_raw(answers, (17..26).to_a),    # Processamento Visual
        'D' => calculate_subscale_raw(answers, (27..39).to_a),     # Processamento Tátil
        'E' => calculate_subscale_raw(answers, (40..49).to_a),    # Nível de Atividade
        'F' => calculate_subscale_raw(answers, (50..60).to_a)     # Processamento Auditivo
      }
    end

    # Calcula raw score de uma categoria específica
    def self.calculate_category_raw(answers, item_numbers)
      item_numbers.map do |num|
        answers["item_#{num}"]&.to_i || 0
      end.sum
    end

    # Calcula raw score de uma subescala específica
    def self.calculate_subscale_raw(answers, item_numbers)
      item_numbers.map do |num|
        answers["item_#{num}"]&.to_i || 0
      end.sum
    end

    # Calcula a idade do paciente se não fornecida
    def self.calculate_patient_age(patient)
      return nil unless patient&.birthday
      
      today = Date.current
      birthday = patient.birthday
      
      age = today.year - birthday.year
      age -= 1 if today < birthday + age.years
      age
    end

    # Determina níveis de processamento sensorial para cada categoria
    def self.determine_category_levels(category_scores)
      category_scores.transform_values do |score|
        determine_category_level_by_score(score)
      end
    end

    # Determina nível de uma categoria específica baseado no score
    def self.determine_category_level_by_score(score)
      case score
      when 0...20 then "Muito menos que a maioria"
      when 20..35 then "Menos que a maioria"
      when 36..50 then "Semelhante a maioria"
      when 51..65 then "Mais que a maioria"
      when 66..75 then "Muito mais que a maioria"
      else "FALSE"
      end
    end

    def self.determine_baixo_registro_level(score, age)
      if age < 18
        case score
        when 0...18 then "Muito menos que a maioria"
        when 19..26 then "Menos que a maioria"
        when 27..40 then "Semelhante a maioria"
        when 41..51 then "Mais que a maioria"
        when 52..75 then "Muito mais que a maioria"
        else "FALSE"
        end
      elsif age >= 18 && age <= 64
        case score
        when 0...18 then "Muito menos que a maioria"
        when 19..23 then "Menos que a maioria"
        when 24..35 then "Semelhante a maioria"
        when 36..44 then "Mais que a maioria"
        when 45..75 then "Muito mais que a maioria"
        else "FALSE"
        end
      elsif age >= 65
        case score
        when 0...19 then "Muito menos que a maioria"
        when 20..26 then "Menos que a maioria"
        when 27..40 then "Semelhante a maioria"
        when 41..51 then "Mais que a maioria"
        when 52..75 then "Muito mais que a maioria"
        else "FALSE"
        end
      else
        "FALSE"
      end
    end

    def self.determine_procura_sensacao_level(score, age)
      if age < 18
        case score
        when 0...27 then "Muito menos que a maioria"
        when 28..41 then "Menos que a maioria"
        when 42..58 then "Semelhante a maioria"
        when 59..65 then "Mais que a maioria"
        when 66..75 then "Muito mais que a maioria"
        else "FALSE"
        end
      elsif age >= 18 && age <= 64
        case score
        when 0...35 then "Muito menos que a maioria"
        when 36..42 then "Menos que a maioria"
        when 43..56 then "Semelhante a maioria"
        when 57..62 then "Mais que a maioria"
        when 63..75 then "Muito mais que a maioria"
        else "FALSE"
        end 
      elsif age >= 65
        case score
        when 0...28 then "Muito menos que a maioria"
        when 29..39 then "Menos que a maioria"
        when 40..52 then "Semelhante a maioria"
        when 53..63 then "Mais que a maioria"
        when 64..75 then "Muito mais que a maioria"
        else "FALSE"
        end
      else
        "FALSE"
      end
    end

    def self.determine_sensibilidade_sensorial_level(score, age)
      if age < 18
        case score
        when 0...19 then "Muito menos que a maioria"
        when 20..25 then "Menos que a maioria"
        when 26..40 then "Semelhante a maioria"
        when 41..48 then "Mais que a maioria"
        when 49..75 then "Muito mais que a maioria"
        else "FALSE"
        end
      elsif age >= 18 && age <= 64
        case score
        when 0...18 then "Muito menos que a maioria"
        when 19..25 then "Menos que a maioria"
        when 26..41 then "Semelhante a maioria"
        when 42..48 then "Mais que a maioria"
        when 49..75 then "Muito mais que a maioria"
        else "FALSE"
        end
      elsif age >= 65
        case score
        when 0...18 then "Muito menos que a maioria"
        when 19..25 then "Menos que a maioria"
        when 26..41 then "Semelhante a maioria"
        when 42..48 then "Mais que a maioria"
        when 49..75 then "Muito mais que a maioria"
        else "FALSE"
        end
      else
        "FALSE"
      end
    end

    def self.determine_evita_sensacao_level(score, age)
      if age < 18
        case score
        when 0...18 then "Muito menos que a maioria"
        when 19..25 then "Menos que a maioria"
        when 26..40 then "Semelhante a maioria"
        when 41..48 then "Mais que a maioria"
        when 49..75 then "Muito mais que a maioria"
        else "FALSE"
        end
      elsif age >= 18 && age <= 64
        case score
        when 0...19 then "Muito menos que a maioria"
        when 20..26 then "Menos que a maioria"
        when 27..41 then "Semelhante a maioria"
        when 42..49 then "Mais que a maioria"
        when 50..75 then "Muito mais que a maioria"
        else "FALSE"
        end
      elsif age >= 65
        case score
        when 0...18 then "Muito menos que a maioria"
        when 19..25 then "Menos que a maioria"
        when 26..42 then "Semelhante a maioria"
        when 43..49 then "Mais que a maioria"
        when 50..75 then "Muito mais que a maioria"
        else "FALSE"
        end
      else
        "FALSE"
      end
    end

    def self.determine_category_description(category, score, age)
      case category
      when 'baixo_registro'
        determine_baixo_registro_level(score, age)
      when 'procura_sensacao'
        determine_procura_sensacao_level(score, age)
      when 'sensibilidade_sensorial'
        determine_sensibilidade_sensorial_level(score, age)
      when 'evita_sensacao'
        determine_evita_sensacao_level(score, age)
      else
        "Descrição não disponível"
      end
    end

    # Determina nível geral baseado no score total
    def self.determine_overall_level(total_score)
      case total_score
      when 0..48 then "normal"
      when 49..96 then "leve"
      when 97..144 then "moderado"
      when 145..300 then "severo"
      else "pontuação_inválida"
      end
    end

    # Constrói o hash de resultados final
    def self.build_result_hash(total_score, category_scores, subscale_scores, category_levels, overall_level, scale_version)
      {
        "schema_version" => 1,
        "scale_code" => "PSA",
        "scale_version" => scale_version,
        "computed_at" => Time.current.iso8601,
        "metrics" => {
          "total_score" => total_score,
          "level" => overall_level
        },
        "category" => build_categories_hash(category_scores, category_levels),
        "subscale" => build_subscales_hash(subscale_scores)
      }
    end

    # Constrói hash das categorias
    def self.build_categories_hash(category_scores, category_levels)
      category_names = {
        'baixo_registro' => 'Baixo Registro',
        'procura_sensacao' => 'Procura Sensação',
        'sensibilidade_sensorial' => 'Sensibilidade Sensorial',
        'evita_sensacao' => 'Evita Sensação'
      }

      result = {}
      category_scores.each do |category, score|
        result[category] = {
          "title" => category_names[category],
          "score" => score.to_s,
          "description" => determine_category_description(category, score, @patient_age)
        }
      end
      result
    end

    # Constrói hash das subescalas
    def self.build_subscales_hash(subscale_scores)
      subscale_names = {
        'A' => 'Processamento Tátil/Olfativo',
        'B' => 'Processamento Vestibular/Proprioceptivo',
        'C' => 'Processamento Visual',
        'D' => 'Processamento Tátil',
        'E' => 'Nível de Atividade',
        'F' => 'Processamento Auditivo'
      }

      subscale_scores.transform_values do |score|
        {
          "title" => subscale_names[subscale_scores.key(score)],
          "score" => score.to_s,
          "average" => calculate_average_score(score, subscale_scores.key(score))
        }
      end
    end

    # Calcula score médio para uma subescala
    def self.calculate_average_score(score, subscale_key)
      item_counts = {
        'A' => 8,   # itens 1-8
        'B' => 8,   # itens 9-16
        'C' => 10,  # itens 17-26
        'D' => 13,  # itens 27-39
        'E' => 10,  # itens 40-49
        'F' => 11   # itens 50-60
      }
      
      item_count = item_counts[subscale_key] || 1
      (score.to_f / item_count).round(1).to_s
    end
  end
end
