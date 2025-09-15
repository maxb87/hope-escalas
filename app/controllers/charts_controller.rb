# frozen_string_literal: true

class ChartsController < ApplicationController
  before_action :set_patient, only: [ :srs2_comparison ]
  before_action :authorize_chart_access

  # Exibe o gráfico de comparação SRS-2
  def srs2_comparison
    @chart_service = Charts::Srs2ComparisonChartService.new(@patient)

    unless @chart_service.has_data?
      flash[:alert] = "Não há dados suficientes para gerar o gráfico de comparação. " \
                     "É necessário ter pelo menos um autorelato e um heterorelato SRS-2 concluídos."
      redirect_to patient_path(@patient) and return
    end

    @chart_data = @chart_service.chart_data
    @report_info = @chart_service.report_info

    # Debug: verificar se os dados estão sendo gerados
    Rails.logger.debug "Chart data: #{@chart_data.inspect}"
    Rails.logger.debug "Report info: #{@report_info.inspect}"
  end

  private

  def set_patient
    @patient = Patient.find(params[:patient_id])
  end

  def authorize_chart_access
    authorize @patient, :show?
  end
end
