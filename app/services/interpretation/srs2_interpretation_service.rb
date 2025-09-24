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

    # Cria um adapter para uma resposta SRS-2
    def self.adapter_for(scale_response)
      Srs2ResponseAdapter.new(scale_response)
    end

    # Busca heterorelato correspondente (mantido para compatibilidade)
    def self.find_hetero_response(scale_response)
      patient = scale_response.patient

      if scale_response.psychometric_scale.code == "SRS2SR"
        # Se é autorelato, buscar heterorelato mais recente
        hetero_response = ScaleResponse.joins(:psychometric_scale)
                                     .where(patient: patient, psychometric_scales: { code: "SRS2HR" })
                                     .where("completed_at IS NOT NULL")
                                     .recent
                                     .first
      elsif scale_response.psychometric_scale.code == "SRS2HR"
        # Se é heterorelato, buscar autorelato
        hetero_response = ScaleResponse.joins(:psychometric_scale)
                                     .where(patient: patient, psychometric_scales: { code: "SRS2SR" })
                                     .where("completed_at IS NOT NULL")
                                     .recent
                                     .first
      end

      hetero_response ? adapter_for(hetero_response) : nil
    end

    # Busca todos os heterorrelatos completados para um paciente
    def self.find_all_hetero_responses(patient)
      ScaleResponse.joins(:psychometric_scale)
                   .where(patient: patient, psychometric_scales: { code: "SRS2HR" })
                   .where("completed_at IS NOT NULL")
                   .order(completed_at: :desc)
    end

    # Busca todos os heterorrelatos completados e retorna como adapters
    def self.find_all_hetero_adapters(patient)
      find_all_hetero_responses(patient).map { |response| adapter_for(response) }
    end

    # Gera a interpretação textual integrada
    def self.generate_integrated_interpretation(self_adapter, hetero_adapter = nil)
      patient = self_adapter.patient

      interpretation = {
        introduction: generate_introduction_text(patient, self_adapter),
        self_report: generate_self_report_text(patient, self_adapter),
        hetero_report: hetero_adapter ? generate_hetero_report_text(patient, hetero_adapter) : ""
      }

      interpretation
    end

    def self.generate_hetero_report_comparison_text(patient, hetero_adapter)
      
    end

    private

    def self.generate_introduction_text(patient, self_adapter)
      t_score = self_adapter.results.dig("metrics", "t_score")
      level_plural = level_pluralize(determine_impairment_level(t_score)[:label])

      "<strong>#{patient.full_name.titleize}</strong> respondeu à Escala SRS-2, instrumento que tem como objetivo " \
      "mensurar sintomas associados ao Transtorno do Espectro Autista (TEA), " \
      "bem como classificá-los em níveis leves, moderados ou severos. #{patient.first_name.capitalize} obteve como pontuação total nesse instrumento #{t_score} pontos, " \
      "caracterizando #{level_plural} relacionados ao TEA, de forma geral. A SRS é uma escala amplamente utilizada para avaliar a " \
      "responsividade social e identificar sinais de comprometimento associados ao TEA."
    end

    def self.generate_self_report_text(patient, self_adapter)
      # Implementar lógica de texto do autorrelato baseado nos domínios
      domains_with_issues = self_adapter.subscale_domains_with_levels.reject { |d| d[:level] == "normal" }

      if domains_with_issues.any?
        "#{patient.first_name.capitalize} apresenta dificuldades nos seguintes domínios: #{format_domains_list(domains_with_issues)}."
      else
        "#{patient.first_name.capitalize} não apresenta dificuldades significativas nos domínios avaliados."
      end
    end


    def self.generate_hetero_report_text(patient, hetero_adapter)
      relator_name = hetero_adapter.relator_name
      relator_relationship = hetero_adapter.relator_relationship
      level_plural = level_pluralize(determine_impairment_level(hetero_adapter.results.dig("metrics", "t_score"))[:label])

      # Verificar se os dados necessários estão presentes
      return "" if relator_name.blank? || relator_relationship.blank?

      text = "De acordo com <strong>#{relator_name}</strong>, " \
             "que é <strong>#{relator_relationship.downcase}</strong> #{patient.gender == 'male' ? 'do' : 'da'} paciente, " \
             "#{patient.first_name.capitalize} apresenta #{level_plural&.downcase || 'resultados'} de forma geral, nos domínios avaliados pela escala SRS-2."

      # Adicionar textos específicos por nível
      text += generate_level_specific_text(patient, hetero_adapter, relator_name)

      text
    end

    def self.generate_level_specific_text(patient, hetero_adapter, relator_name)
      text = ""

      # Verificar se relator_name não é nil
      return text if relator_name.blank?

      relator_first_name = relator_name.split(" ").first&.capitalize || relator_name

      if hetero_adapter.leve_domains.any?
        text += " Em sua visão, #{patient.first_name.capitalize} " \
                "demonstra algumas dificuldades nos domínios de #{hetero_adapter.print_leve_domains}."
      end

      if hetero_adapter.moderado_domains.any?
        text += " #{hetero_adapter.print_moderado_domains} #{hetero_adapter.moderado_domains.count > 1 ? 'foram classificados' : 'foi classificado'} por #{relator_first_name} " \
                "em nível moderado, identificando claramente #{hetero_adapter.moderado_domains.count > 1 ? 'áreas' : 'uma área'} de dificuldade."
      end

      if hetero_adapter.severo_domains.any?
        text += " #{hetero_adapter.severo_domains.count > 1 ? 'Destacaram-se' : 'Destaca-se'} " \
                "#{hetero_adapter.print_severo_domains} " \
                "como #{hetero_adapter.severo_domains.count > 1 ? 'pontos' : 'ponto'} em que " \
                "#{patient.gender == 'male' ? 'o' : 'a'} paciente apresenta nível severo de prejuízo " \
                "e requer maior atenção."
      end

      if hetero_adapter.normal_domains.any?
        text += " #{relator_first_name} " \
                "não observou necessidades significativas em relação a #{hetero_adapter.print_normal_domains}."
      end

      text
    end

    def self.format_domains_list(domains)
      domain_names = domains.map { |d| d[:title] }
      case domain_names.size
      when 1
        domain_names.first
      when 2
        "#{domain_names.first} e #{domain_names.last}"
      else
        "#{domain_names[0..-2].join(', ')} e #{domain_names.last}"
      end
    end


   
  end
end
