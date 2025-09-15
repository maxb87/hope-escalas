# frozen_string_literal: true

module InterpretationHelper
  # Gera o HTML para a interpretação SRS-2
  def srs2_interpretation(interpretation_data, options = {})
    return content_tag(:div, "Dados insuficientes para interpretação.", class: "alert alert-warning") unless interpretation_data.present?

    content_tag :div, class: "srs2-interpretation #{options[:class]}" do
      [
        interpretation_header(interpretation_data),
        interpretation_text(interpretation_data),
        domain_analysis_section(interpretation_data),
        comparison_section(interpretation_data)
      ].compact.join.html_safe
    end
  end

  # Gera informações sobre os relatórios
  def interpretation_report_info(report_info)
    return unless report_info.present?

    content_tag :div, class: "interpretation-report-info" do
      content_tag :div, class: "row g-4" do
        [
          self_report_info_section(report_info[:self_report]),
          hetero_report_info_section(report_info[:hetero_report])
        ].compact.join.html_safe
      end
    end
  end

  # Gera link para a interpretação SRS-2
  def srs2_interpretation_link(patient, text = nil, options = {})
    text ||= "Ver Interpretação SRS-2"
    link_to srs2_interpretation_path(patient),
            class: "btn btn-outline-primary #{options[:class]}",
            title: "Ver interpretação detalhada dos resultados SRS-2" do
      content_tag(:i, "", class: "bi bi-clipboard-data me-1") + text
    end
  end

  # Gera tabela de comparação entre autorelato e heterorelato
  def srs2_comparison_table(comparison_data)
    return unless comparison_data.present? && comparison_data.any?

    content_tag :div, class: "table-responsive" do
      content_tag :table, class: "table table-bordered table-striped" do
        [
          comparison_table_header,
          comparison_table_body(comparison_data)
        ].join.html_safe
      end
    end
  end

  # Gera tabela de análise por domínios
  def srs2_domain_analysis_table(domain_analysis)
    return unless domain_analysis.present? && domain_analysis.any?

    content_tag :div, class: "table-responsive" do
      content_tag :table, class: "table table-bordered table-striped" do
        [
          domain_analysis_table_header,
          domain_analysis_table_body(domain_analysis)
        ].join.html_safe
      end
    end
  end

  private

  def interpretation_header(data)
    content_tag :div, class: "interpretation-header mb-4" do
      content_tag :h4, class: "mb-2" do
        content_tag(:i, "", class: "bi bi-clipboard-check me-2") + "Interpretação dos Resultados"
      end
    end
  end

  def interpretation_text(data)
    return unless data[:overall_interpretation].present?

    content_tag :div, class: "interpretation-text mb-4" do
      content_tag :p, data[:overall_interpretation][:text], class: "lead"
    end
  end

  def domain_analysis_section(data)
    return unless data[:domain_analysis].present? && data[:domain_analysis].any?

    content_tag :div, class: "domain-analysis mb-4" do
      [
        content_tag(:h5, "Análise por Domínios", class: "mb-3"),
        srs2_domain_analysis_table(data[:domain_analysis])
      ].join.html_safe
    end
  end

  def comparison_section(data)
    return unless data[:comparison].present? && data[:comparison].any?

    content_tag :div, class: "comparison-section mb-4" do
      [
        content_tag(:h5, "Comparação Autorelato vs Heterorelato", class: "mb-3"),
        srs2_comparison_table(data[:comparison])
      ].join.html_safe
    end
  end

  def self_report_info_section(self_report_info)
    return unless self_report_info.present?

    content_tag :div, class: "col-md-6" do
      content_tag :div, class: "card" do
        content_tag :div, class: "card-body" do
          [
            content_tag(:h6, "Autorelato", class: "card-title"),
            content_tag(:p, "Paciente: #{self_report_info[:patient_name]}", class: "mb-1"),
            content_tag(:p, "Solicitado em: #{l(self_report_info[:requested_at], format: :short)}", class: "mb-1"),
            content_tag(:p, "Preenchido em: #{l(self_report_info[:completed_at], format: :short)}", class: "mb-0")
          ].join.html_safe
        end
      end
    end
  end

  def hetero_report_info_section(hetero_report_info)
    return unless hetero_report_info.present?

    content_tag :div, class: "col-md-6" do
      content_tag :div, class: "card" do
        content_tag :div, class: "card-body" do
          [
            content_tag(:h6, "Heterorelato", class: "card-title"),
            content_tag(:p, "Paciente: #{hetero_report_info[:patient_name]}", class: "mb-1"),
            content_tag(:p, "Relator: #{hetero_report_info[:relator_name]} (#{hetero_report_info[:relator_relationship]})", class: "mb-1"),
            content_tag(:p, "Solicitado em: #{l(hetero_report_info[:requested_at], format: :short)}", class: "mb-1"),
            content_tag(:p, "Preenchido em: #{l(hetero_report_info[:completed_at], format: :short)}", class: "mb-0")
          ].join.html_safe
        end
      end
    end
  end

  def comparison_table_header
    content_tag :thead, class: "table-dark" do
      content_tag :tr do
        [
          content_tag(:th, "Domínio"),
          content_tag(:th, "Autorelato (T-Score)"),
          content_tag(:th, "Heterorelato (T-Score)"),
          content_tag(:th, "Diferença"),
          content_tag(:th, "Nível Autorelato"),
          content_tag(:th, "Nível Heterorelato")
        ].join.html_safe
      end
    end
  end

  def comparison_table_body(comparison_data)
    content_tag :tbody do
      comparison_data.map do |domain|
        content_tag :tr do
          [
            content_tag(:td, domain[:name]),
            content_tag(:td, domain[:self_t_score] || "N/A"),
            content_tag(:td, domain[:hetero_t_score] || "N/A"),
            content_tag(:td, domain[:difference] || "N/A"),
            content_tag(:td, content_tag(:span, domain[:self_level], class: "badge bg-#{level_badge_class(domain[:self_level])}")),
            content_tag(:td, content_tag(:span, domain[:hetero_level], class: "badge bg-#{level_badge_class(domain[:hetero_level])}"))
          ].join.html_safe
        end
      end.join.html_safe
    end
  end

  def domain_analysis_table_header
    content_tag :thead, class: "table-dark" do
      content_tag :tr do
        [
          content_tag(:th, "Domínio"),
          content_tag(:th, "T-Score"),
          content_tag(:th, "Nível"),
          content_tag(:th, "Interpretação")
        ].join.html_safe
      end
    end
  end

  def domain_analysis_table_body(domain_analysis)
    content_tag :tbody do
      domain_analysis.map do |domain|
        content_tag :tr do
          [
            content_tag(:td, domain[:name]),
            content_tag(:td, domain[:t_score] || "N/A"),
            content_tag(:td, content_tag(:span, domain[:level], class: "badge bg-#{level_badge_class(domain[:level])}")),
            content_tag(:td, domain[:interpretation])
          ].join.html_safe
        end
      end.join.html_safe
    end
  end

  def level_badge_class(level)
    case level
    when "normal"
      "success"
    when "leve"
      "warning"
    when "moderado"
      "warning"
    when "severo"
      "danger"
    else
      "secondary"
    end
  end
end
