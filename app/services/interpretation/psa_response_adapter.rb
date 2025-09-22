# frozen_string_literal: true

module Interpretation
  class PsaResponseAdapter
    delegate :patient, :results, :scale_request, :completed_at, :psychometric_scale, to: :@scale_response

    def initialize(scale_response)
      @scale_response = scale_response
      raise ArgumentError, "Scale response must be PSA" unless @scale_response.psa_scale?
    end

    # Ordem das categorias PSA
    CATEGORY_ORDER = [
      "A", # Processamento Tátil/Olfativo
      "B", # Processamento Vestibular/Proprioceptivo
      "C", # Processamento Visual
      "D", # Processamento Tátil
      "E", # Nível de Atividade
      "F"  # Processamento Auditivo
    ].freeze

    # Retorna uma lista das categorias com seus níveis para uso na view
    def category_domains_with_levels
      return [] unless results.present? && results["categories"].present?

      categories = results["categories"]
      ordered_categories = []

      CATEGORY_ORDER.each do |category_key|
        next unless categories[category_key]

        category_data = categories[category_key]
        category_info = build_category_info(category_key, category_data)
        ordered_categories << category_info
      end

      ordered_categories
    end

    # Métodos para acessar diferentes aspectos dos resultados
    def total_score
      results.dig("metrics", "raw_score") || 0
    end

    def total_possible
      results.dig("metrics", "total_possible") || 300
    end

    def interpretation_level
      results.dig("interpretation", "level") || "Não disponível"
    end

    def interpretation_description
      results.dig("interpretation", "description") || ""
    end

    # Retorna comentários das categorias
    def category_comments
      results.dig("comments") || {}
    end

    # Verifica se há comentários para uma categoria específica
    def has_comment_for?(category)
      category_comments[category].present?
    end

    # Retorna o comentário de uma categoria específica
    def comment_for(category)
      category_comments.dig(category, "comment")
    end

    # Estatísticas gerais
    def completion_percentage
      return 0 if total_possible.zero?
      (total_score.to_f / total_possible * 100).round(1)
    end

    # Categorias com maior responsividade (média >= 4.0)
    def high_responsivity_categories
      return [] unless results.present? && results["categories"].present?

      results["categories"].select { |_, data| data["average"] >= 4.0 }
                          .map { |category, data| { category: category, data: data } }
    end

    # Categorias com menor responsividade (média <= 2.0)
    def low_responsivity_categories
      return [] unless results.present? && results["categories"].present?

      results["categories"].select { |_, data| data["average"] <= 2.0 }
                          .map { |category, data| { category: category, data: data } }
    end

    # Categorias balanceadas (média entre 2.0 e 4.0)
    def balanced_categories
      return [] unless results.present? && results["categories"].present?

      results["categories"].select { |_, data| data["average"] > 2.0 && data["average"] < 4.0 }
                          .map { |category, data| { category: category, data: data } }
    end

    private

    def build_category_info(category_key, category_data)
      {
        category: category_key,
        title: category_data["name"],
        total_score: category_data["total"],
        average_score: category_data["average"],
        interpretation: category_data["interpretation"],
        completion_rate: category_data["completion_rate"],
        has_comment: has_comment_for?(category_key),
        comment: comment_for(category_key)
      }
    end
  end
end
