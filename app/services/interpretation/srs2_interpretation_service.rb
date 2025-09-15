# frozen_string_literal: true

module Interpretation
  class Srs2InterpretationService
    # Níveis de prejuízo baseados no T-Score
    IMPAIRMENT_LEVELS = {
      normal: {
        min: 0,
        max: 54,
        label: "normal"
      },
      mild_impairment: {
        min: 55,
        max: 64,
        label: "leve"
      },
      moderate_impairment: {
        min: 65,
        max: 74,
        label: "moderado"
      },
      severe_impairment: {
        min: 75,
        max: 100,
        label: "severo"
      }
    }.freeze

    # Retorna descrição da interpretação baseada no nível
    def get_interpretation_description(patient, self_report)
      # Determinar o nível de prejuízo baseado no T-Score total
      t_score = self_report.respond_to?(:t_total) ? self_report.t_total : self_report.dig("metrics", "t_score")
      level = self.class.determine_impairment_level(t_score)
      level_plural = self.class.level_pluralize(level[:label])

      response = "#{patient.full_name.capitalize} respondeu à SRS-2, instrumento que tem como objetivo mensurar sintomas associados ao Transtorno do Espectro Autista (TEA), " \
                 "bem como classificá-los em níveis leves, moderados ou severos. #{patient.first_name.capitalize} obteve como pontuação total neste instrumento #{t_score} pontos, " \
                 "caracterizando #{level_plural} relacionados ao TEA, de forma geral. A SRS é uma escala amplamente utilizada para avaliar a " \
                 "responsividade social e identificar sinais de comprometimento associados ao TEA."

      response
    end

    # Gera tabela de comparação entre autorelato e heterorelato com T-scores
    def self.get_comparison_table(self_report, hetero_report)
      return "" unless self_report && hetero_report

      # Mapeamento dos domínios
      domains = [
        { key: "social_awareness", label: "Percepção Social" },
        { key: "social_cognition", label: "Cognição Social" },
        { key: "social_communication", label: "Comunicação Social" },
        { key: "social_motivation", label: "Motivação Social" },
        { key: "restricted_interests", label: "Interesses Restritos/Repetitivos" },
        { key: "social_interaction", label: "Interação Social" },
        { key: "total", label: "Total" }
      ]

      # Início da tabela HTML
      html = <<~HTML
        <table class="table table-bordered table-striped">
          <thead class="table-dark">
            <tr>
              <th>Domínio</th>
              <th>Autorelato (T-Score)</th>
              <th>Heterorelato (T-Score)</th>
            </tr>
          </thead>
          <tbody>
      HTML

      # Adiciona linhas para cada domínio
      domains.each do |domain|
        # Obtém os T-scores para cada domínio
        self_t_score = get_domain_t_score(self_report, domain[:key])
        hetero_t_score = get_domain_t_score(hetero_report, domain[:key])

        html += <<~HTML
            <tr>
              <td>#{domain[:label]}</td>
              <td>#{self_t_score || 'N/A'}</td>
              <td>#{hetero_t_score || 'N/A'}</td>
            </tr>
        HTML
      end

      # Fecha a tabela
      html += <<~HTML
          </tbody>
        </table>
      HTML

      html.html_safe
    end

    def self.self_report_integrated_description(patient, self_report)
      "#{patient.first_name.capitalize} apresenta dificuldades clínicamente relevantes nos seguintes domínios:"
    end

    # Método auxiliar para obter o T-score de um domínio específico
    def self.get_domain_t_score(report, domain_key)
      return nil unless report

      # Tenta diferentes formas de acessar os dados dependendo da estrutura
      if report.respond_to?(domain_key)
        report.send(domain_key)
      elsif report.respond_to?(:dig)
        # Para estruturas hash ou similar
        case domain_key
        when "total"
          report.dig("metrics", "t_score") || report.dig("t_total") || report["t_total"]
        else
          report.dig("domains", domain_key, "t_score") ||
          report.dig(domain_key, "t_score") ||
          report.dig("t_#{domain_key}")
        end
      elsif report.is_a?(Hash)
        # Para hash simples
        case domain_key
        when "total"
          report["t_total"] || report["total_t_score"]
        else
          report["t_#{domain_key}"] || report[domain_key]
        end
      end
    end

    def self.determine_interpretation_level(raw_score)
      t_score = Srs2LookupService.calculate_total_t_score(raw_score)
      level = determine_impairment_level(t_score)
      level[:label]
    end

    def self.level_pluralize(level)
      case level
      when "leve"
        "prejuízos leves"
      when "moderado"
        "prejuízos moderados"
      when "severo"
        "prejuízos severos"
      else
        "ausência de prejuízos significativos"
      end
    end

    # Determina o nível de prejuízo baseado no T-Score
    def self.determine_impairment_level(t_score)
      IMPAIRMENT_LEVELS.each do |key, level|
        return level if t_score >= level[:min] && t_score <= level[:max]
      end
      IMPAIRMENT_LEVELS[:severe_impairment] # fallback
    end
  end
end
