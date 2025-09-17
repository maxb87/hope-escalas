# frozen_string_literal: true

module Interpretation
  class Srs2ResponseAdapter
    delegate :patient, :relator_name, :relator_relationship, :results, :scale_request, :completed_at, :psychometric_scale, to: :@scale_response

    def initialize(scale_response)
      @scale_response = scale_response
      raise ArgumentError, "Scale response must be SRS-2" unless @scale_response.srs2_scale?
    end

    # Ordem específica dos domínios conforme solicitado
    DOMAIN_ORDER = [
      "social_awareness",      # Percepção Social
      "social_cognition",      # Cognição Social
      "social_communication",  # Comunicação Social
      "social_motivation",     # Motivação Social
      "restricted_interests",  # Padrões Restritos ou Repetitivos
      "social_interaction"     # Interação Social Global
    ].freeze

    # Retorna uma lista dos domínios das subescalas com seus níveis para uso na view
    def subscale_domains_with_levels
      return [] unless results.present? && results["subscales"].present?

      subscales = results["subscales"]
      ordered_domains = []
      normal_domains = []

      DOMAIN_ORDER.each do |domain_key|
        next unless subscales[domain_key]

        domain_data = subscales[domain_key]
        domain_info = build_domain_info(domain_key, domain_data)

        # Separar domínios normais dos problemáticos
        if domain_data["level"] == "normal"
          normal_domains << domain_info
        else
          ordered_domains << domain_info
        end
      end

      # Manter a ordem específica dos domínios
      ordered_domains + normal_domains
    end

    # Métodos para filtrar domínios por nível
    %w[leve moderado severo normal].each do |level|
      define_method "#{level}_domains" do
        subscale_domains_with_levels.select { |domain| domain[:level] == level }
      end

      define_method "print_#{level}_domains" do
        domains = send("#{level}_domains").map { |domain| domain[:title] }
        format_domain_list(domains)
      end
    end

    # Retorna o domínio com maior severidade
    def worst_domain
      if severo_domains.any?
        severo_domains.max_by { |domain| domain[:t_score] }
      elsif moderado_domains.any?
        moderado_domains.max_by { |domain| domain[:t_score] }
      elsif leve_domains.any?
        leve_domains.max_by { |domain| domain[:t_score] }
      else
        normal_domains.max_by { |domain| domain[:t_score] }
      end
    end

    def lowest_domain
      if leve_domains.any?
        leve_domains.min_by { |domain| domain[:t_score] }
      elsif moderado_domains.any?
        moderado_domains.min_by { |domain| domain[:t_score] }
      elsif severo_domains.any?
        severo_domains.min_by { |domain| domain[:t_score] }
      else
        normal_domains.min_by { |domain| domain[:t_score] }
      end
    end

    # Retorna o domínio com a segunda maior pontuação
    def second_highest_domain
      all_domains = subscale_domains_with_levels
      return nil if all_domains.size < 2

      sorted_domains = all_domains.sort_by { |domain| -domain[:t_score] }
      sorted_domains[1]
    end

    # Segundo maior dentro de cada categoria de severidade
    def second_worst_domain
      if severo_domains.size >= 2
        severo_domains.sort_by { |domain| -domain[:t_score] }[1]
      elsif severo_domains.size == 1 && moderado_domains.any?
        moderado_domains.max_by { |domain| domain[:t_score] }
      elsif severo_domains.empty? && moderado_domains.size >= 2
        moderado_domains.sort_by { |domain| -domain[:t_score] }[1]
      elsif moderado_domains.size == 1 && leve_domains.any?
        leve_domains.max_by { |domain| domain[:t_score] }
      elsif moderado_domains.empty? && leve_domains.size >= 2
        leve_domains.sort_by { |domain| -domain[:t_score] }[1]
      elsif leve_domains.size == 1 && normal_domains.any?
        normal_domains.max_by { |domain| domain[:t_score] }
      elsif leve_domains.empty? && normal_domains.size >= 2
        normal_domains.sort_by { |domain| -domain[:t_score] }[1]
      else
        nil
      end
    end

    private

    attr_reader :scale_response

    def build_domain_info(domain_key, domain_data)
      {
        key: domain_key,
        title: domain_data["title"],
        level: domain_data["level"],
        t_score: domain_data["t_score"],
        raw_score: domain_data["raw_score"],
        percentile: domain_data["percentile"],
        description: domain_data["description"],
        interpretation: domain_data["interpretation"],
        items: domain_data["items"]
      }
    end

    def format_domain_list(domains)
      case domains.size
      when 0
        ""
      when 1
        domains.first
      when 2
        "#{domains.first} e #{domains.last}"
      else
        "#{domains[0..-2].join(', ')} e #{domains.last}"
      end
    end
  end
end
