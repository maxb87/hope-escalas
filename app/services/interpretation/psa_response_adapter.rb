# frozen_string_literal: true

module Interpretation
  class PsaResponseAdapter
    delegate :patient, :results, :scale_request, :completed_at, :psychometric_scale, to: :@scale_response

    def initialize(scale_response)
      @scale_response = scale_response
      raise ArgumentError, "Scale response must be PSA" unless @scale_response.psa_scale?
    end

    # Calcula o total_score corretamente a partir dos results
    def total_score
      return @scale_response.total_score unless results.present? && results["total_score"].present?
      results["total_score"]
    end

    # Ordem específica das categorias PSA
    CATEGORY_ORDER = [
      "A",  # Processamento Tátil/Olfativo
      "B",  # Processamento Vestibular/Proprioceptivo
      "C",  # Processamento Visual
      "D",  # Processamento Tátil
      "E",  # Nível de Atividade
      "F"   # Processamento Auditivo
    ].freeze

    # Retorna uma lista das categorias com seus níveis para uso na view
    def categories_with_levels
      return [] unless results.present? && results["categories"].present?

      categories = results["categories"]
      ordered_categories = []
      normal_categories = []

      CATEGORY_ORDER.each do |category_code|
        next unless categories[category_code]

        category_data = categories[category_code]
        category_info = build_category_info(category_code, category_data)

        # Separar categorias normais das problemáticas
        if category_data["level"] == "normal"
          normal_categories << category_info
        else
          ordered_categories << category_info
        end
      end

      # Manter a ordem específica das categorias
      ordered_categories + normal_categories
    end

    # Métodos para filtrar categorias por nível
    %w[leve moderado severo normal].each do |level|
      define_method("categories_with_#{level}_level") do
        categories_with_levels.select { |cat| cat[:level] == level }
      end
    end

    # Retorna categorias com dificuldades (não normais)
    def categories_with_difficulties
      categories_with_levels.reject { |cat| cat[:level] == "normal" }
    end

    # Retorna categorias normais
    def normal_categories
      categories_with_levels.select { |cat| cat[:level] == "normal" }
    end

    # Retorna score total
    def total_score
      results&.dig("total_score") || 0
    end

    # Retorna nível geral
    def overall_level
      results&.dig("overall_level") || "normal"
    end

    # Retorna interpretação geral
    def overall_interpretation
      results&.dig("interpretation", "description") || "Interpretação não disponível"
    end

    # Retorna recomendações
    def recommendations
      results&.dig("interpretation", "recommendations") || []
    end

    # Retorna se há dificuldades no processamento sensorial
    def has_difficulties?
      categories_with_difficulties.any?
    end

    # Retorna quantidade de categorias com dificuldades
    def difficulties_count
      categories_with_difficulties.count
    end

    # Retorna se é PSA
    def psa_scale?
      true
    end

    # Retorna se é SRS-2 (sempre false para PSA)
    def srs2_scale?
      false
    end

    # Retorna descrição do nível para exibição
    def level_description(level)
      case level
      when "normal" then "Normal"
      when "leve" then "Leve dificuldade"
      when "moderado" then "Moderada dificuldade"
      when "severo" then "Severa dificuldade"
      else "Nível não determinado"
      end
    end

    # Retorna cor do nível para exibição
    def level_color(level)
      case level
      when "normal" then "success"
      when "leve" then "warning"
      when "moderado" then "warning"
      when "severo" then "danger"
      else "secondary"
      end
    end

    private

    # Constrói informações de uma categoria
    def build_category_info(category_code, category_data)
      items_count = category_data["items_count"] || 0
      {
        code: category_code,
        title: category_data["name"],
        score: category_data["score"],
        level: category_data["level"],
        description: category_data["description"],
        items_count: items_count,
        max_possible_score: items_count * 5  # 5 é o máximo na escala Likert
      }
    end
  end
end
