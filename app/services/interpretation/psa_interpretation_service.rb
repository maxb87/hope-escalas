# frozen_string_literal: true

module Interpretation
  class PsaInterpretationService
    # Níveis de processamento sensorial baseados no score
    PROCESSING_LEVELS = {
      normal: {
        min: 0,
        max: 8,
        label: "normal"
      },
      mild_difficulty: {
        min: 9,
        max: 16,
        label: "leve"
      },
      moderate_difficulty: {
        min: 17,
        max: 24,
        label: "moderado"
      },
      severe_difficulty: {
        min: 25,
        max: 40,
        label: "severo"
      }
    }.freeze

    # Retorna descrição da interpretação baseada no nível
    def get_interpretation_description(patient, self_report)
      # Determinar o nível geral baseado no score total
      total_score = self_report.respond_to?(:total_score) ? self_report.total_score : self_report.dig("total_score")
      level = self.class.determine_processing_level(total_score)
      level_plural = self.class.level_pluralize(level[:label])

      response = "#{patient.full_name.capitalize} respondeu a escala PSA - Perfil Sensorial do Adulto/Adolescente, " \
                 "instrumento que tem como objetivo avaliar o processamento sensorial em diferentes categorias. " \
                 "O PSA é uma escala amplamente utilizada para avaliar o perfil sensorial e identificar dificuldades no processamento de informações sensoriais." \

      response
    end

    # Gera interpretação textual integrada para PSA
    def self.generate_integrated_interpretation(self_adapter)
      patient = self_adapter.patient
      results = self_adapter.results

      interpretation = {
        introduction: generate_introduction(patient, results),
        categories_analysis: generate_categories_analysis(results),
        overall_interpretation: generate_overall_interpretation(results)
      }

      interpretation
    end

    # Gera texto de introdução
    def self.generate_introduction(patient, results)
      # A estrutura do scoring/psa.rb usa "metrics" para total_score e level
      metrics = results["metrics"] || {}
      total_score = metrics["total_score"] || results["total_score"]
      overall_level = metrics["level"] || results["overall_level"]
      
      level_description = case overall_level
      when "normal"
        "dentro da normalidade"
      when "leve"
        "com leve dificuldade"
      when "moderado"
        "com moderada dificuldade"
      when "severo"
        "com severa dificuldade"
      else
        "com dificuldade no processamento sensorial"
      end

      "O PSA - Perfil Sensorial do Adulto/Adolescente foi aplicado em #{patient.full_name} " \
      "e revelou um perfil sensorial DESCRIPTION#{}. A pontuação total de #{total_score} pontos " \
      "indica características específicas no processamento de informações sensoriais que podem " \
      "influenciar o funcionamento diário e a participação em atividades."
    end

    # Gera análise das categorias
    def self.generate_categories_analysis(results)
      # A estrutura do scoring/psa.rb usa "category" (singular), não "categories"
      categories = results["category"] || results["categories"]
      
      # Verificar se as categorias existem e têm a estrutura correta
      return "Análise das categorias não disponível para este registro." unless categories.present?
      
      # Verificar se as categorias têm a estrutura correta do novo formato
      if categories.values.first.is_a?(Integer)
        # Dados antigos com estrutura incorreta - pular análise por enquanto
        return "Análise das categorias não disponível para este registro."
      end
      
      # Classificar categorias por nível de dificuldade
      classification = classify_categories_by_level(categories)
      
      # Gerar análise baseada na classificação
      generate_analysis_by_classification(classification)
    end

    # Gera análise das subescalas
    def self.generate_subscales_analysis(results, patient_age = nil)
      subscales = results["subscale"] || results["subscales"]
      
      # Verificar se as subescalas existem
      return "Análise das subescalas não disponível para este registro." unless subscales.present?
      
      # Classificar subescalas por nível de dificuldade baseado na faixa etária
      classification = classify_subscales_by_level_with_age(subscales, patient_age)
      
      # Gerar análise baseada na classificação
      generate_subscales_analysis_by_classification(classification)
    end

    private

    def self.classify_categories_by_level(categories)
      classification = {
        "muito_abaixo" => [],
        "abaixo" => [],
        "media" => [],
        "acima" => [],
        "muito_acima" => []
      }
      
      categories.each do |code, category|
        description = category["description"] || category["interpretation"] || ""
        title = category["title"] || code.humanize
        score = category["score"] || "N/A"
        
        category_data = {
          title: title,
          description: description,
          score: score,
          code: code
        }
        
        case description
        when /Muito menos que a maioria/
          classification["muito_abaixo"] << category_data
        when /Menos que a maioria/
          classification["abaixo"] << category_data
        when /Semelhante a maioria/
          classification["media"] << category_data
        when /Mais que a maioria/
          classification["acima"] << category_data
        when /Muito mais que a maioria/
          classification["muito_acima"] << category_data
        else
          # Se não conseguir classificar, colocar na média
          classification["media"] << category_data
        end
      end
      
      classification
    end

    def self.generate_analysis_by_classification(classification)
      analysis_parts = []
      
      # Análise das categorias muito abaixo da média
      if classification["muito_abaixo"].any?
        analysis_parts << "**Categorias Muito Abaixo da Média:**"
        classification["muito_abaixo"].each do |cat|
          analysis_parts << "• #{cat[:title]}: #{cat[:description]} (Pontuação: #{cat[:score]})"
        end
        analysis_parts << ""
      end
      
      # Análise das categorias abaixo da média
      if classification["abaixo"].any?
        analysis_parts << "**Categorias Abaixo da Média:**"
        classification["abaixo"].each do |cat|
          analysis_parts << "• #{cat[:title]}: #{cat[:description]} (Pontuação: #{cat[:score]})"
        end
        analysis_parts << ""
      end
      
      # Análise das categorias na média
      if classification["media"].any?
        analysis_parts << "**Categorias na Média:**"
        classification["media"].each do |cat|
          analysis_parts << "• #{cat[:title]}: #{cat[:description]} (Pontuação: #{cat[:score]})"
        end
        analysis_parts << ""
      end
      
      # Análise das categorias acima da média
      if classification["acima"].any?
        analysis_parts << "**Categorias Acima da Média:**"
        classification["acima"].each do |cat|
          analysis_parts << "• #{cat[:title]}: #{cat[:description]} (Pontuação: #{cat[:score]})"
        end
        analysis_parts << ""
      end
      
      # Análise das categorias muito acima da média
      if classification["muito_acima"].any?
        analysis_parts << "**Categorias Muito Acima da Média:**"
        classification["muito_acima"].each do |cat|
          analysis_parts << "• #{cat[:title]}: #{cat[:description]} (Pontuação: #{cat[:score]})"
        end
        analysis_parts << ""
      end
      
      # Adicionar interpretação geral
      analysis_parts << generate_overall_interpretation(classification)
      
      analysis_parts.join("\n")
    end

    def self.generate_overall_interpretation(classification)
      total_categories = classification.values.flatten.length
      below_normal = classification["muito_abaixo"].length + classification["abaixo"].length
      above_normal = classification["acima"].length + classification["muito_acima"].length
      normal = classification["media"].length
      
      interpretation = "\n**Interpretação Geral:**\n"
      
      if below_normal == 0 && above_normal == 0
        interpretation += "Perfil sensorial equilibrado com todas as categorias dentro da normalidade."
      elsif below_normal > above_normal
        interpretation += "Perfil sensorial com tendência a baixa responsividade sensorial. " \
                         "Pode indicar necessidade de estímulos mais intensos para processamento adequado."
      elsif above_normal > below_normal
        interpretation += "Perfil sensorial com tendência a alta responsividade sensorial. " \
                         "Pode indicar sensibilidade aumentada que requer estratégias de modulação."
      else
        interpretation += "Perfil sensorial misto com características variadas. " \
                         "Requer avaliação individualizada para cada área específica."
      end
      
      interpretation
    end

    def self.classify_subscales_by_level(subscales)
      classification = {
        "maior_dificuldade" => [],
        "menor_dificuldade" => [],
        "media" => []
      }
      
      # Converter scores para números para análise
      subscale_scores = subscales.map do |code, subscale|
        score = subscale["score"].to_f
        average = subscale["average"].to_f
        deviation = score - average
        {
          code: code,
          title: subscale["title"] || get_subscale_title(code),
          score: score,
          average: average,
          deviation: deviation,
          difficulty_level: calculate_difficulty_level(score, average)
        }
      end
      
      # Ordenar por desvio da média (desvio mais alto = maior dificuldade)
      subscale_scores.sort_by! { |sub| -sub[:deviation] }
      
      # Classificar em grupos baseado no desvio da média
      subscale_scores.each do |subscale|
        case subscale[:difficulty_level]
        when "Muito acima da média", "Acima da média"
          classification["maior_dificuldade"] << subscale
        when "Na média"
          classification["media"] << subscale
        when "Abaixo da média", "Muito abaixo da média"
          classification["menor_dificuldade"] << subscale
        end
      end
      
      classification
    end

    def self.classify_subscales_by_level_with_age(subscales, patient_age)
      classification = {
        "maior_dificuldade" => [],
        "menor_dificuldade" => [],
        "media" => []
      }
      
      # Converter scores para números para análise
      subscale_scores = subscales.map do |code, subscale|
        score = subscale["score"].to_f
        average = subscale["average"].to_f
        deviation = score - average
        {
          code: code,
          title: subscale["title"] || get_subscale_title(code),
          score: score,
          average: average,
          deviation: deviation,
          difficulty_level: calculate_difficulty_level_by_age(score, average, patient_age)
        }
      end
      
      # Ordenar por desvio da média (desvio mais alto = maior dificuldade)
      subscale_scores.sort_by! { |sub| -sub[:deviation] }
      
      # Classificar em grupos baseado no desvio da média
      subscale_scores.each do |subscale|
        case subscale[:difficulty_level]
        when "Muito acima da média", "Acima da média"
          classification["maior_dificuldade"] << subscale
        when "Na média"
          classification["media"] << subscale
        when "Abaixo da média", "Muito abaixo da média"
          classification["menor_dificuldade"] << subscale
        end
      end
      
      classification
    end

    def self.calculate_difficulty_level_by_age(score, average, patient_age)
      # Calcular desvio da média para determinar dificuldade
      deviation = score - average
      
      # Ajustar critérios baseado na faixa etária
      case patient_age
      when 0...18
        # Critérios para menores de 18 anos
        case deviation
        when -Float::INFINITY..-2.0
          "Muito abaixo da média"
        when -2.0...-1.0
          "Abaixo da média"
        when -1.0..1.0
          "Na média"
        when 1.0...2.0
          "Acima da média"
        else
          "Muito acima da média"
        end
      when 18..64
        # Critérios para adultos (18-64 anos)
        case deviation
        when -Float::INFINITY..-1.5
          "Muito abaixo da média"
        when -1.5...-0.5
          "Abaixo da média"
        when -0.5..0.5
          "Na média"
        when 0.5...1.5
          "Acima da média"
        else
          "Muito acima da média"
        end
      when 65..Float::INFINITY
        # Critérios para idosos (65+ anos)
        case deviation
        when -Float::INFINITY..-1.0
          "Muito abaixo da média"
        when -1.0...-0.5
          "Abaixo da média"
        when -0.5..0.5
          "Na média"
        when 0.5...1.0
          "Acima da média"
        else
          "Muito acima da média"
        end
      else
        # Fallback para idade não especificada
        case deviation
        when -Float::INFINITY..-1.5
          "Muito abaixo da média"
        when -1.5...-0.5
          "Abaixo da média"
        when -0.5..0.5
          "Na média"
        when 0.5...1.5
          "Acima da média"
        else
          "Muito acima da média"
        end
      end
    end

    def self.calculate_difficulty_level(score, average)
      # Calcular desvio da média para determinar dificuldade
      deviation = score - average
      
      case deviation
      when -Float::INFINITY..-1.5
        "Muito abaixo da média"
      when -1.5...-0.5
        "Abaixo da média"
      when -0.5..0.5
        "Na média"
      when 0.5...1.5
        "Acima da média"
      else
        "Muito acima da média"
      end
    end

    def self.get_subscale_title(code)
      subscale_titles = {
        'A' => 'Processamento Tátil/Olfativo',
        'B' => 'Processamento Vestibular/Proprioceptivo',
        'C' => 'Processamento Visual',
        'D' => 'Processamento Tátil',
        'E' => 'Nível de Atividade',
        'F' => 'Processamento Auditivo'
      }
      subscale_titles[code] || code
    end

    def self.generate_subscales_analysis_by_classification(classification)
      analysis_parts = []
      
      # Análise das subescalas com maior dificuldade
      if classification["maior_dificuldade"].any?
        analysis_parts << "<strong>Grupos de Média Superior:</strong>"
        classification["maior_dificuldade"].each do |subscale|
          analysis_parts << "• #{subscale[:title]} (#{subscale[:code]}): Pontuação #{subscale[:score]} (Média: #{subscale[:average]}) - #{subscale[:difficulty_level]}"
        end
        analysis_parts << ""
      end
      
      # Análise das subescalas na média
      if classification["media"].any?
        analysis_parts << "<strong>Compatíveis com a Média da População:</strong>"
        classification["media"].each do |subscale|
          analysis_parts << "• #{subscale[:title]} (#{subscale[:code]}): Pontuação #{subscale[:score]} (Média: #{subscale[:average]}) - #{subscale[:difficulty_level]}"
        end
        analysis_parts << ""
      end
      
      # Análise das subescalas com menor dificuldade
      if classification["menor_dificuldade"].any?
        analysis_parts << "<strong>Grupos de Média Inferior:</strong>"
        classification["menor_dificuldade"].each do |subscale|
          analysis_parts << "• #{subscale[:title]} (#{subscale[:code]}): Pontuação #{subscale[:score]} (Média: #{subscale[:average]}) - #{subscale[:difficulty_level]}"
        end
        analysis_parts << ""
      end
      
      # Adicionar interpretação geral das subescalas
      analysis_parts << generate_subscales_overall_interpretation(classification)
      
      analysis_parts.join("\n")
    end

    def self.generate_subscales_overall_interpretation(classification)
      total_subscales = classification.values.flatten.length
      high_difficulty = classification["maior_dificuldade"].length
      low_difficulty = classification["menor_dificuldade"].length
      normal = classification["media"].length
      
      interpretation = "\n<strong>Interpretação Geral:</strong>\n"
      
      # Sempre exibir texto sobre altas dificuldades se presentes
      if high_difficulty > 0
        interpretation += "Perfil sensorial caracterizado por subescalas de média superior. " \
                        "Estas características podem indicar necessidade de controle dos estímulos sensoriais associados, " \
                        "estratégias de modulação ou adaptações nos ambientes.\n\n"
      end
      
      # Sempre exibir texto sobre baixas dificuldades se presentes
      if low_difficulty > 0
        interpretation += "Algumas áreas abaixo da média da população podem indicar necessidade de estímulos mais intensos para percepção normal. " \
                        "Estratégias de exposição controlada ou sensibilização podem ser utilizadas. O aumento de estímulos pode ser utilizado para o desenvolvimento da capacidade de processamento sensorial.\n\n"
      end
      
      # Exibir texto sobre perfil equilibrado apenas quando não há altas ou baixas dificuldades
      if high_difficulty == 0 && low_difficulty == 0
        interpretation += "Todas as subescalas estão dentro da normalidade para a faixa etária do paciente, " \
                        "comparado com o restante da população, indicando um perfil sensorial equilibrado."
      end
      
      interpretation
    end


    # Gera interpretação geral
    def self.generate_overall_interpretation(results)
      # A estrutura do scoring/psa.rb usa "metrics" para level
      metrics = results["metrics"] || {}
      overall_level = metrics["level"] || results["overall_level"]
      total_score = metrics["total_score"] || results["total_score"]
      
      case overall_level
      when "normal"
        "O perfil sensorial está dentro da normalidade, " \
        "indicando que o processamento de informações sensoriais está funcionando adequadamente " \
        "em todas as categorias avaliadas."
      when "leve"
        "O perfil sensorial apresenta leve dificuldade no processamento sensorial. " \
        "Algumas categorias podem apresentar pequenas alterações que, embora não sejam " \
        "significativas, podem beneficiar de estratégias de apoio."
      when "moderado"
        "O perfil sensorial apresenta moderada dificuldade no processamento sensorial. " \
        "Várias categorias apresentam alterações que podem impactar o funcionamento diário " \
        "e requerem intervenção especializada."
      when "severo"
        "O perfil sensorial apresenta severa dificuldade no processamento sensorial. " \
        "Múltiplas categorias apresentam alterações significativas que impactam " \
        "substancialmente o funcionamento diário e requerem intervenção intensiva."
      else
        "A interpretação do perfil sensorial requer análise mais detalhada dos resultados."
      end
    end


    # Determina nível de processamento baseado no score total
    def self.determine_processing_level(total_score)
      case total_score
      when 0..48 then PROCESSING_LEVELS[:normal]
      when 49..96 then PROCESSING_LEVELS[:mild_difficulty]
      when 97..144 then PROCESSING_LEVELS[:moderate_difficulty]
      when 145..240 then PROCESSING_LEVELS[:severe_difficulty]
      else
        { min: 0, max: 0, label: "inválido" }
      end
    end

    # Pluraliza nível para uso em texto
    def self.level_pluralize(level)
      case level
      when "normal" then "características normais"
      when "leve" then "leve dificuldade"
      when "moderado" then "moderada dificuldade"
      when "severo" then "severa dificuldade"
      else "dificuldades no processamento sensorial"
      end
    end

    # Cria adapter para resposta PSA
    def self.adapter_for(scale_response)
      PsaResponseAdapter.new(scale_response)
    end

  end
end
