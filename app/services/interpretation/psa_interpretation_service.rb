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

      response = "#{patient.full_name.capitalize} respondeu ao PSA - Perfil Sensorial do Adulto/Adolescente, " \
                 "instrumento que tem como objetivo avaliar o processamento sensorial em diferentes categorias. " \
                 "#{patient.first_name.capitalize} obteve como pontuação total neste instrumento #{total_score} pontos, " \
                 "caracterizando #{level_plural} no processamento sensorial, de forma geral. O PSA é uma escala " \
                 "amplamente utilizada para avaliar o perfil sensorial e identificar dificuldades no processamento " \
                 "de informações sensoriais."

      response
    end

    # Gera interpretação textual integrada para PSA
    def self.generate_integrated_interpretation(self_adapter)
      patient = self_adapter.patient
      results = self_adapter.results

      interpretation = {
        introduction: generate_introduction(patient, results),
        categories_analysis: generate_categories_analysis(results),
        overall_interpretation: generate_overall_interpretation(results),
        recommendations: generate_recommendations(results)
      }

      interpretation
    end

    # Gera texto de introdução
    def self.generate_introduction(patient, results)
      total_score = results["total_score"]
      overall_level = results["overall_level"]
      
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
      "e revelou um perfil sensorial #{level_description}. A pontuação total de #{total_score} pontos " \
      "indica características específicas no processamento de informações sensoriais que podem " \
      "influenciar o funcionamento diário e a participação em atividades."
    end

    # Gera análise das categorias
    def self.generate_categories_analysis(results)
      categories = results["categories"]
      categories_with_difficulties = categories.select { |_, cat| cat["level"] != "normal" }
      
      if categories_with_difficulties.empty?
        "Todas as categorias de processamento sensorial estão dentro da normalidade, " \
        "indicando um perfil sensorial equilibrado e funcional."
      else
        analysis = "As seguintes categorias apresentaram dificuldades no processamento sensorial:\n\n"
        
        categories_with_difficulties.each do |code, category|
          analysis += "• #{category['name']}: #{category['description']} (Pontuação: #{category['score']})\n"
        end
        
        analysis += "\nEssas dificuldades podem impactar o funcionamento diário e requerem " \
                   "atenção especializada para melhorar a qualidade de vida."
      end
    end

    # Gera interpretação geral
    def self.generate_overall_interpretation(results)
      overall_level = results["overall_level"]
      total_score = results["total_score"]
      
      case overall_level
      when "normal"
        "O perfil sensorial de #{results.dig('patient_info', 'name')} está dentro da normalidade, " \
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

    # Gera recomendações
    def self.generate_recommendations(results)
      recommendations = results.dig("interpretation", "recommendations") || []
      
      if recommendations.empty?
        "Continue monitorando o perfil sensorial e considere reavaliação periódica " \
        "para acompanhar mudanças no processamento sensorial."
      else
        "Recomendações baseadas no perfil sensorial:\n\n" +
        recommendations.map.with_index(1) { |rec, i| "#{i}. #{rec}" }.join("\n")
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

    # PSA não possui heterorrelatos, então retorna nil
    def self.find_hetero_response(scale_response)
      nil
    end

    # PSA não possui heterorrelatos, então retorna array vazio
    def self.find_all_hetero_responses(patient)
      []
    end

    # PSA não possui heterorrelatos, então retorna array vazio
    def self.find_all_hetero_adapters(patient)
      []
    end
  end
end
