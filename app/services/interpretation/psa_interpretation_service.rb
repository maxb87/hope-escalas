# frozen_string_literal: true

module Interpretation
  class PsaInterpretationService
    # Níveis de responsividade sensorial baseados na média das categorias
    RESPONSIVITY_LEVELS = {
      very_low: {
        min: 1.0,
        max: 1.5,
        label: "muito baixa",
        description: "Pouca percepção ou resposta aos estímulos sensoriais"
      },
      low: {
        min: 1.5,
        max: 2.5,
        label: "baixa",
        description: "Menor sensibilidade aos estímulos sensoriais do ambiente"
      },
      typical: {
        min: 2.5,
        max: 3.5,
        label: "típica",
        description: "Processamento sensorial dentro dos padrões esperados"
      },
      high: {
        min: 3.5,
        max: 4.5,
        label: "alta",
        description: "Maior sensibilidade aos estímulos sensoriais"
      },
      very_high: {
        min: 4.5,
        max: 5.0,
        label: "muito alta",
        description: "Extrema sensibilidade aos estímulos sensoriais"
      }
    }.freeze

    # Gera interpretação detalhada dos resultados PSA
    def self.generate_interpretation(scale_response_adapter)
      patient = scale_response_adapter.patient
      interpretation_level = scale_response_adapter.interpretation_level

      # Análise por categorias
      high_categories = scale_response_adapter.high_responsivity_categories
      low_categories = scale_response_adapter.low_responsivity_categories
      balanced_categories = scale_response_adapter.balanced_categories

      # Construir narrativa interpretativa
      narrative = build_interpretation_narrative(
        patient,
        interpretation_level,
        high_categories,
        low_categories,
        balanced_categories,
        scale_response_adapter
      )

      # Recomendações baseadas no perfil
      recommendations = generate_recommendations(high_categories, low_categories)

      {
        narrative: narrative,
        recommendations: recommendations,
        summary: build_summary(scale_response_adapter)
      }
    end

    # Cria um adapter para uma resposta PSA
    def self.adapter_for(scale_response)
      PsaResponseAdapter.new(scale_response)
    end

    # Método principal para gerar interpretação integrada
    def self.generate_integrated_interpretation(scale_response_adapter, hetero_response = nil)
      generate_interpretation(scale_response_adapter)
    end

    private

    def self.build_interpretation_narrative(patient, interpretation_level, high_categories, low_categories, balanced_categories, adapter)
      narrative = []

      # Introdução
      narrative << "#{patient.full_name} respondeu ao Perfil Sensorial do Adulto/Adolescente (PSA), " \
                   "instrumento que avalia como uma pessoa processa e responde a diferentes tipos de " \
                   "estímulos sensoriais no ambiente."

      # Padrão geral
      narrative << "O perfil geral indica: #{interpretation_level.downcase}."

      # Análise das categorias com alta responsividade
      unless high_categories.empty?
        category_names = high_categories.map { |cat| cat[:data]["name"] }
        narrative << "#{patient.first_name} demonstra alta responsividade sensorial nas seguintes áreas: " \
                     "#{category_names.join(', ')}. Isso sugere maior sensibilidade a estes tipos de " \
                     "estímulos, podendo necessitar de estratégias de autorregulação."
      end

      # Análise das categorias com baixa responsividade
      unless low_categories.empty?
        category_names = low_categories.map { |cat| cat[:data]["name"] }
        narrative << "Por outro lado, apresenta baixa responsividade em: #{category_names.join(', ')}. " \
                     "Isso pode indicar menor percepção destes estímulos ou necessidade de estímulos " \
                     "mais intensos para gerar respostas."
      end

      # Análise das categorias balanceadas
      unless balanced_categories.empty?
        category_names = balanced_categories.map { |cat| cat[:data]["name"] }
        narrative << "Nas áreas de #{category_names.join(', ')}, #{patient.first_name} apresenta " \
                     "responsividade dentro dos padrões típicos."
      end

      # Incluir comentários relevantes se disponíveis
      comments_analysis = analyze_comments(adapter)
      narrative << comments_analysis if comments_analysis.present?

      narrative.join(" ")
    end

    def self.analyze_comments(adapter)
      comments = adapter.category_comments
      return nil if comments.empty?

      comment_insights = []

      comments.each do |category, comment_data|
        if comment_data["comment"].present?
          comment_insights << "Em #{comment_data['category']}, #{adapter.patient.first_name} relatou: \"#{comment_data['comment']}\""
        end
      end

      if comment_insights.any?
        "Observações pessoais relevantes: #{comment_insights.join('. ')}"
      end
    end

    def self.generate_recommendations(high_categories, low_categories)
      recommendations = []

      # Recomendações para alta responsividade
      unless high_categories.empty?
        recommendations << {
          title: "Estratégias para Alta Responsividade Sensorial",
          items: [
            "Identificar e modificar ambientes que causam sobrecarga sensorial",
            "Desenvolver técnicas de autorregulação (respiração, pausas sensoriais)",
            "Usar ferramentas adaptativas (protetores auriculares, óculos escuros, etc.)",
            "Planejar gradualmente a exposição a estímulos desafiadores"
          ]
        }
      end

      # Recomendações para baixa responsividade
      unless low_categories.empty?
        recommendations << {
          title: "Estratégias para Baixa Responsividade Sensorial",
          items: [
            "Incorporar atividades com estímulos mais intensos na rotina",
            "Usar alertas visuais ou táteis para aumentar a consciência sensorial",
            "Praticar atividades que envolvam movimento e propriocepção",
            "Estabelecer rotinas que incluam 'pausas sensoriais' estimulantes"
          ]
        }
      end

      # Recomendações gerais
      recommendations << {
        title: "Recomendações Gerais",
        items: [
          "Manter um diário sensorial para identificar padrões",
          "Comunicar necessidades sensoriais em ambientes sociais e de trabalho",
          "Considerar avaliação com terapeuta ocupacional especializado em integração sensorial",
          "Explorar técnicas de mindfulness e consciência corporal"
        ]
      }

      recommendations
    end

    def self.build_summary(adapter)
      {
        total_score: "#{adapter.total_score}/#{adapter.total_possible}",
        completion_percentage: "#{adapter.completion_percentage}%",
        interpretation_level: adapter.interpretation_level,
        categories_analyzed: adapter.category_domains_with_levels.count,
        comments_provided: adapter.category_comments.count
      }
    end
  end
end
