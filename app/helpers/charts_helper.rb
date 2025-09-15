# frozen_string_literal: true

module ChartsHelper
  # Gera o HTML para o gráfico de comparação SRS-2
  def srs2_comparison_chart(chart_data, options = {})
    container_id = options[:id] || "srs2-comparison-chart"
    height = options[:height] || "400px"

    # Debug: verificar se os dados estão presentes
    Rails.logger.debug "Chart data: #{chart_data.inspect}"

    content_tag :div, class: "chart-container", style: "height: #{height};" do
      content_tag :canvas, "", id: container_id, data: { chart_data: chart_data.to_json }
    end
  end

  # Gera informações sobre os relatórios
  def chart_report_info(report_info)
    return unless report_info.present?

    content_tag :div, class: "chart-report-info" do
      content_tag :div, class: "row g-4" do
        [
          self_report_info_section(report_info[:self_report]),
          hetero_report_info_section(report_info[:hetero_report])
        ].compact.join.html_safe
      end
    end
  end

  # Gera link para o gráfico de comparação
  def srs2_comparison_chart_link(patient, text = nil, options = {})
    text ||= "Ver Gráfico de Comparação SRS-2"
    link_to srs2_comparison_charts_path(patient),
            class: "btn btn-outline-primary #{options[:class]}",
            title: "Comparar autorelato e heterorelato SRS-2" do
      content_tag(:i, "", class: "bi bi-graph-up me-1") + text
    end
  end

  private

  def self_report_info_section(self_report_info)
    return unless self_report_info.present?

    content_tag :div, class: "col-md-6" do
      content_tag :div, class: "card h-100 border-secondary shadow-sm" do
        content_tag(:div, class: "card-header bg-light border-secondary") do
          content_tag(:h6, "Autorrelato", class: "card-title mb-0 text-secondary fw-bold") +
          content_tag(:i, "", class: "bi bi-person-circle ms-2 text-secondary")
        end +
        content_tag(:div, class: "card-body d-flex flex-column") do
          [
            content_tag(:div, class: "mb-3") do
              content_tag(:div, class: "d-flex align-items-center mb-2") do
                content_tag(:i, "", class: "bi bi-person-fill me-2 text-secondary") +
                content_tag(:span, self_report_info[:patient_name], class: "fw-semibold text-dark")
              end
            end,
            content_tag(:div, class: "mb-2") do
              content_tag(:div, class: "d-flex align-items-center") do
                content_tag(:i, "", class: "bi bi-calendar-event me-2 text-secondary") +
                content_tag(:span, "Solicitado em: ", class: "text-muted") +
                content_tag(:span, l(self_report_info[:requested_at], format: :short), class: "fw-medium")
              end
            end,
            content_tag(:div, class: "mt-auto") do
              content_tag(:div, class: "d-flex align-items-center") do
                content_tag(:i, "", class: "bi bi-check-circle me-2 text-success") +
                content_tag(:span, "Concluído em: ", class: "text-muted") +
                content_tag(:span, l(self_report_info[:completed_at], format: :short), class: "fw-medium text-success")
              end
            end
          ].join.html_safe
        end
      end
    end
  end

  def hetero_report_info_section(hetero_report_info)
    return unless hetero_report_info.present?

    content_tag :div, class: "col-md-6" do
      content_tag :div, class: "card h-100 border-primary shadow-sm" do
        content_tag(:div, class: "card-header bg-light border-primary") do
          content_tag(:h6, "Heterorrelato", class: "card-title mb-0 text-primary fw-bold") +
          content_tag(:i, "", class: "bi bi-people-fill ms-2 text-primary")
        end +
        content_tag(:div, class: "card-body d-flex flex-column") do
          [
            content_tag(:div, class: "mb-3") do
              content_tag(:div, class: "d-flex align-items-center mb-2") do
                content_tag(:i, "", class: "bi bi-person-badge me-2 text-primary") +
                content_tag(:span, hetero_report_info[:relator_name], class: "fw-semibold text-dark")
              end
            end,
            content_tag(:div, class: "mb-2") do
              content_tag(:div, class: "d-flex align-items-center") do
                content_tag(:i, "", class: "bi bi-calendar-event me-2 text-primary") +
                content_tag(:span, "Solicitado em: ", class: "text-muted") +
                content_tag(:span, l(hetero_report_info[:requested_at], format: :short), class: "fw-medium")
              end
            end,
            content_tag(:div, class: "mt-auto") do
              content_tag(:div, class: "d-flex align-items-center") do
                content_tag(:i, "", class: "bi bi-check-circle me-2 text-success") +
                content_tag(:span, "Concluído em: ", class: "text-muted") +
                content_tag(:span, l(hetero_report_info[:completed_at], format: :short), class: "fw-medium text-success")
              end
            end
          ].join.html_safe
        end
      end
    end
  end
end
