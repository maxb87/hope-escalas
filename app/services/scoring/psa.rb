# frozen_string_literal: true
# reference: https://www.studocu.com/pt-br/document/instituto-de-pos-graduacao-e-graduacao/neuropsicologia/perfil-sensorial-do-adulto-adolescente/95684872

module Scoring
  class Psa
    # Calcula resultados para o PSA - Perfil Sensorial do Adulto/Adolescente
    # answers: { "item_1"=>"1", "item_2"=>"3", ... }
    # patient_gender: 'male' ou 'female' (opcional para PSA)
    # patient_age: idade em anos (opcional para PSA)
    def self.calculate(answers, scale_version: "1.0", patient_gender: nil, patient_age: nil, patient: nil)
      # Armazenar o paciente em uma variável de classe para uso nas interpretações
      @patient = patient

      # Calcular scores por categoria
      category_scores = calculate_category_scores(answers)
      
      # Calcular score total
      total_score = category_scores.values.sum
      
      # Determinar níveis de processamento sensorial
      category_levels = determine_category_levels(category_scores)
      
      # Gerar interpretação geral
      overall_level = determine_overall_level(total_score)
      
      build_result_hash(total_score, category_scores, category_levels, overall_level, scale_version, patient)
    end

    private

    # Calcula scores para cada categoria PSA
    def self.calculate_category_scores(answers)
      {
        'baixo_registro' => calculate_category_raw(answers, [3,6,12,15,21,23,36,37,39,41,44,45,52,55,59]),      # Processamento Tátil/Olfativo
        'procura_sensacao'calculate_category_raw(answers, [2,4,8,10,14,17,19,28,30,32,40,42,47,50,58]), # Processamento Vestibular/Proprioceptivo
        'sensibilidade_sensorial' => calculate_category_raw(answers, [7,9,13,16,20,22,25,27,31,33,34,48,51,54,60]), # Processamento Visual
        'evita_sensacao' => calculate_category_raw(answers, [1,5,11,18,24,26,29,35,38,43,46,49,53,56,57]),    # Processamento Tátil  
      }
    end
    

    def self.calculate_subscale_scores(answers)
      {
        'A' => calculate_subscale_raw(answers, (1..8).to_a),      # Processamento Tátil/Olfativo
        'B' => calculate_subscale_raw(answers, (9..16).to_a), # Processamento Vestibular/Proprioceptivo
        'C' => calculate_subscale_raw(answers, (17..26).to_a), # Processamento Visual
        'D' => calculate_subscale_raw(answers, (27..39).to_a),    # Processamento Tátil  
        'E' => calculate_subscale_raw(answers, (40..49).to_a),    # Nível de Atividade  
        'F' => calculate_subscale_raw(answers, (50..60).to_a),    # Processamento Auditivo  
      }
    end

    # Calcula raw score de uma categoria específica
    def self.calculate_category_raw(answers, item_numbers)
      item_numbers.map do |num|
        raw_value = answers["item_#{num}"]&.to_i || 0
        raw_value  # PSA usa escala 1-5 diretamente, sem inversões
      end.sum
    end

    # Determina níveis de processamento sensorial para cada categoria
    def self.determine_category_levels(category_scores)
      category_scores.transform_values do |score|
        determine_category_level(score)
      end
    end

    # Determina nível de uma categoria específica baseado no score
    def self.determine_category_level(category, score, age)
      #TODO: implement per category
    end

    def self.determine_baixo_registro_level(score, age)
        case age
        when age < 18
          case score
          when score < 18 then "Muito menos que a maioria"
          when 19..26 then "Menos que a maioria"
          when 27..40 then "Semelhante a maioria"
          when 41..51 then "Mais que a maioria"
          when 52..75 then "Muito mais que a maioria"
          else "FALSE"
          end
        when age >= 18 and age <= 64
          case score
          when score < 18 then "Muito menos que a maioria"
          when 19..23 then "Menos que a maioria"
          when 24..35 then "Semelhante a maioria"
          when 36..44 then "Mais que a maioria"
          when 45..75 then "Muito mais que a maioria"
          else "FALSE"
          end
        when age >= 65
          case score
          when score < 19 then "Muito menos que a maioria"
          when 20..26 then "Menos que a maioria"
          when 27..40 then "Semelhante a maioria"
          when 41..51 then "Mais que a maioria"
          when 52..75 then "Muito mais que a maioria"
          else "FALSE"
          end
        end
    end

    def self.determine_procura_sensacao_level(score, age)
      case age
      when age < 18
        case score
        when score < 27 then "Muito menos que a maioria"
        when 28..41 then "Menos que a maioria"
        when 42..58 then "Semelhante a maioria"
        when 59..65 then "Mais que a maioria"
        when 66..75 then "Muito mais que a maioria"
        else "FALSE"
        end
      when age >= 18 and age <= 64
        case score
        when score < 35 then "Muito menos que a maioria"
        when 36..42 then "Menos que a maioria"
        when 43..56 then "Semelhante a maioria"
        when 57..62 then "Mais que a maioria"
        when 63..75 then "Muito mais que a maioria"
        else "FALSE"
        end 
      when age >= 65
        case score
        when score < 28 then "Muito menos que a maioria"
        when 29..39 then "Menos que a maioria"
        when 40..52 then "Semelhante a maioria"
        when 53..63 then "Mais que a maioria"
        when 64..75 then "Muito mais que a maioria"
        else "FALSE"
        end
      end
    end

    def self.determine_sensibilidade_sensorial_level(score, age)
      case age
      when age < 18
        case score
        when score < 19 then "Muito menos que a maioria"
        when 20..25 then "Menos que a maioria"
        when 26..40 then "Semelhante a maioria"
        when 41..48 then "Mais que a maioria"
        when 49..75 then "Muito mais que a maioria"
        else "FALSE"
        end
      when age >= 18 and age <= 64
        case score
        when score < 18 then "Muito menos que a maioria"
        when 19..25 then "Menos que a maioria"
        when 26..41 then "Semelhante a maioria"
        when 42..48 then "Mais que a maioria"
        when 49..75 then "Muito mais que a maioria"
        else "FALSE"
        end
      when age >= 65
        case score
        when score < 18 then "Muito menos que a maioria"
        when 19..25 then "Menos que a maioria"
        when 26..41 then "Semelhante a maioria"
        when 42..48 then "Mais que a maioria"
        when 49..75 then "Muito mais que a maioria"
        else "FALSE"
        end
      end
    end

    def self.determine_evita_sensacao_level(score, age)
      case age
      when age < 18
        case score
        when score < 18 then "Muito menos que a maioria"
        when 19..25 then "Menos que a maioria"
        when 26..40 then "Semelhante a maioria"
        when 41..48 then "Mais que a maioria"
        when 49..75 then "Muito mais que a maioria"
        else "FALSE"
        end
      when age >= 18 and age <= 64
        case score
        when score < 19 then "Muito menos que a maioria"
        when 20..26 then "Menos que a maioria"
        when 27..41 then "Semelhante a maioria"
        when 42..49 then "Mais que a maioria"
        when 50..75 then "Muito mais que a maioria"
        else "FALSE"
        end
      when age >= 65
        case score
        when score < 18 then "Muito menos que a maioria"
        when 19..25 then "Menos que a maioria"
        when 26..42 then "Semelhante a maioria"
        when 43..49 then "Mais que a maioria"
        when 49..75 then "Muito mais que a maioria"
        else "FALSE"
        end
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

    def self.determine_subscale_level(subscale, score)
      # TODO: implement this
    end

    # Constrói o hash de resultados final
    def self.build_result_hash(total_score, category_scores, category_levels, overall_level, scale_version, patient)
      {
        "schema_version" => 1,
        "scale_code" => "PSA",
        "scale_version" => scale_version,
        "computed_at" => Time.current.iso8601,
        "metrics" => {
          "total_score"=> total_score
        },
        "comments" => {},
        "subscales" => build_subscales_hash(category_scores, category_levels),
        "categories" => build_categories_hash(category_scores, category_levels),
        "interpretation" => build_interpretation_hash(overall_level, category_levels, total_score),
        
      }
    end


    def self.build_categories_hash(category_scores, category_levels)
      # TODO: double check implementation. Search for standard ratios
      category_names = {
        'baixo_registro' => 'Processamento Tátil/Olfativo',
        'procura_sensacao' => 'Processamento Vestibular/Proprioceptivo',
        'sensibilidade_sensorial' => 'Processamento Visual',
        'evita_sensacao' => 'Processamento Tátil'
      }

      result = {}
      category_scores.each do |key, score|
        result[category_names[key]] = {
          "raw_score" => score,
          "average_score" => average_score,
          "interpretation" => get_interpretation_text(category_levels[key]),
        }
      end
      result
    end
    
    # Constrói hash das subscalas (formato da imagem)
    def self.build_subscales_hash(category_scores, category_levels)
      category_names = {
        'A' => 'Processamento Tátil/Olfativo',
        'B' => 'Processamento Vestibular/Proprioceptivo', 
        'C' => 'Processamento Visual',
        'D' => 'Processamento Tátil',
        'E' => 'Nível de Atividade',
        'F' => 'Processamento Auditivo'
      }

      result = {}
      category_scores.each do |key, score|
        items_count = get_category_items_count(key)
        average_score = items_count > 0 ? (score.to_f / items_count).round(2) : 0.0
        
        result["category_#{key.downcase}"] = {
          "raw_score" => score,
          "average_score" => average_score,
          "interpretation" => get_interpretation_text(category_levels[key]),
        }
      end
      result
    end

    # Constrói hash das categorias com informações detalhadas
    def self.build_categories_hash(category_scores, category_levels)
      category_names = {
        'A' => 'Processamento Tátil/Olfativo',
        'B' => 'Processamento Vestibular/Proprioceptivo', 
        'C' => 'Processamento Visual',
        'D' => 'Processamento Tátil',
        'E' => 'Nível de Atividade',
        'F' => 'Processamento Auditivo'
      }

      result = {}
      category_scores.each do |key, score|
        items_count = get_category_items_count(key)
        average_score = items_count > 0 ? (score.to_f / items_count).round(2) : 0.0
        
        result[key] = {
          "total" => score,
          "average" => average_score,
          "interpretation" => get_interpretation_text(category_levels[key]),
        }
      end
      result
    end

    # Converte nível para texto de interpretação
    def self.get_interpretation_text(level)
      case level
      when "normal"
        "Raramente/Ocasionalmente"
      when "leve"
        "Ocasionalmente/Frequentemente"
      when "moderado"
        "Frequentemente/Sempre"
      when "severo"
        "Sempre"
      else
        "Não disponível"
      end
    end

    # Retorna descrição de uma categoria específica
    def self.get_category_description(category_code, level)
      descriptions = {
        'A' => {
          "normal" => "Processamento tátil/olfativo dentro da normalidade",
          "leve" => "Leve dificuldade no processamento tátil/olfativo",
          "moderado" => "Moderada dificuldade no processamento tátil/olfativo",
          "severo" => "Severa dificuldade no processamento tátil/olfativo"
        },
        'B' => {
          "normal" => "Processamento vestibular/proprioceptivo dentro da normalidade",
          "leve" => "Leve dificuldade no processamento vestibular/proprioceptivo",
          "moderado" => "Moderada dificuldade no processamento vestibular/proprioceptivo",
          "severo" => "Severa dificuldade no processamento vestibular/proprioceptivo"
        },
        'C' => {
          "normal" => "Processamento visual dentro da normalidade",
          "leve" => "Leve dificuldade no processamento visual",
          "moderado" => "Moderada dificuldade no processamento visual",
          "severo" => "Severa dificuldade no processamento visual"
        },
        'D' => {
          "normal" => "Processamento tátil dentro da normalidade",
          "leve" => "Leve dificuldade no processamento tátil",
          "moderado" => "Moderada dificuldade no processamento tátil",
          "severo" => "Severa dificuldade no processamento tátil"
        },
        'E' => {
          "normal" => "Nível de atividade dentro da normalidade",
          "leve" => "Leve alteração no nível de atividade",
          "moderado" => "Moderada alteração no nível de atividade",
          "severo" => "Severa alteração no nível de atividade"
        },
        'F' => {
          "normal" => "Processamento auditivo dentro da normalidade",
          "leve" => "Leve dificuldade no processamento auditivo",
          "moderado" => "Moderada dificuldade no processamento auditivo",
          "severo" => "Severa dificuldade no processamento auditivo"
        }
      }

      descriptions[category_code][level] || "Descrição não disponível"
    end

    # Retorna quantidade de itens por categoria
    def self.get_category_items_count(category_code)
      {
        'A' => 8,   # itens 1-8
        'B' => 8,   # itens 9-16
        'C' => 10,  # itens 17-26
        'D' => 13,  # itens 27-39
        'E' => 10,  # itens 40-49
        'F' => 11   # itens 50-60
      }[category_code] || 0
    end

    # Constrói hash de interpretação geral
    def self.build_interpretation_hash(overall_level, category_levels, total_score)
      categories_with_low_responsiveness = category_levels.select { |_, level| level == "normal" }.keys
      
      {
        "level" => get_overall_interpretation_level(overall_level),
        "description" => get_overall_interpretation_description(overall_level, total_score, categories_with_low_responsiveness)
      }
    end

    # Retorna nível de interpretação geral
    def self.get_overall_interpretation_level(level)
      case level
      when "normal"
        "Padrão típico de responsividade sensorial"
      when "leve"
        "Padrão leve de responsividade sensorial"
      when "moderado"
        "Padrão moderado de responsividade sensorial"
      when "severo"
        "Padrão severo de responsividade sensorial"
      else
        "Padrão não disponível"
      end
    end

    # Retorna descrição da interpretação geral
    def self.get_overall_interpretation_description(level, total_score, categories_with_low_responsiveness)
      category_names = {
        'A' => 'Processamento Tátil/Olfativo',
        'B' => 'Processamento Vestibular/Proprioceptivo', 
        'C' => 'Processamento Visual',
        'D' => 'Processamento Tátil',
        'E' => 'Nível de Atividade',
        'F' => 'Processamento Auditivo'
      }
      
      low_categories = categories_with_low_responsiveness.map { |cat| category_names[cat] }.join(", ")
      
      if low_categories.present?
        "Pontuação total: #{total_score}/300. Categorias com baixa responsividade: #{low_categories}"
      else
        "Pontuação total: #{total_score}/300. Todas as categorias dentro da normalidade." 
      end
    end

    # Retorna recomendações baseadas no nível geral e categorias
    def self.get_recommendations(overall_level, category_levels)
      recommendations = []
      
      # Recomendações gerais baseadas no nível
      case overall_level
      when "leve"
        recommendations << "Considerar avaliação mais detalhada com terapeuta ocupacional especializado em integração sensorial."
      when "moderado"
        recommendations << "Recomenda-se intervenção terapêutica com terapeuta ocupacional especializado em integração sensorial."
        recommendations << "Considerar avaliação multidisciplinar."
      when "severo"
        recommendations << "Recomenda-se intervenção terapêutica intensiva com equipe multidisciplinar."
        recommendations << "Avaliação médica pode ser necessária para descartar outras condições."
      end

      # Recomendações específicas por categoria
      category_levels.each do |category, level|
        next if level == "normal"
        
        case category
        when 'A', 'D'  # Tátil
          recommendations << "Considerar estratégias de dessensibilização ou sensibilização tátil."
        when 'B'  # Vestibular/Proprioceptivo
          recommendations << "Considerar atividades de movimento e propriocepção para regular o sistema vestibular."
        when 'C'  # Visual
          recommendations << "Considerar adaptações ambientais para reduzir sobrecarga visual."
        when 'E'  # Nível de Atividade
          recommendations << "Considerar estratégias para regular o nível de atividade e atenção."
        when 'F'  # Auditivo
          recommendations << "Considerar estratégias para regular o processamento auditivo e reduzir sobrecarga sensorial."
        end
      end

      recommendations.uniq
    end
  end
end
