class ScaleResponsesController < ApplicationController
  include ChartsHelper

  before_action :set_scale_response, only: [ :show, :interpretation, :destroy ]

  def index
    @scale_responses = policy_scope(ScaleResponse).includes(:patient, :psychometric_scale, :scale_request)
    authorize @scale_responses
  end

  def new
    @scale_request = ScaleRequest.find(params[:scale_request_id])
    authorize @scale_request, :respond?

    # Verificação adicional: se já existe resposta, redirecionar
    if @scale_request.scale_response.present?
      redirect_back_with_alert(I18n.t("scale_responses.errors.already_completed"))
      return
    end

    # Verificação adicional: se não está pendente, redirecionar
    unless @scale_request.pending?
      redirect_back_with_alert(I18n.t("scale_responses.errors.not_pending"))
      return
    end

    @scale_response = ScaleResponse.new
    @scale_response.scale_request = @scale_request
    @scale_response.patient = @scale_request.patient
    @scale_response.psychometric_scale = @scale_request.psychometric_scale

    @scale_items = @scale_request.psychometric_scale.scale_items.ordered
    authorize @scale_response
  end

  def create
    @scale_request = ScaleRequest.find(params[:scale_request_id])
    authorize @scale_request, :respond?

    # Verificação adicional: se já existe resposta, redirecionar
    if @scale_request.scale_response.present?
      redirect_back_with_alert(I18n.t("scale_responses.errors.already_completed"))
      return
    end

    # Verificação adicional: se não está pendente, redirecionar
    unless @scale_request.pending?
      redirect_back_with_alert(I18n.t("scale_responses.errors.not_pending"))
      return
    end

    @scale_response = ScaleResponse.new(scale_response_params)
    @scale_response.scale_request = @scale_request
    @scale_response.patient = @scale_request.patient
    @scale_response.psychometric_scale = @scale_request.psychometric_scale

    authorize @scale_response

    if @scale_response.save
      @scale_request.complete!
      redirect_after_success
    else
      @scale_items = @scale_request.psychometric_scale.scale_items.ordered
      flash.now[:alert] = I18n.t("errors.messages.not_saved", count: @scale_response.errors.count, resource: @scale_response.class.model_name.human.downcase)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    authorize @scale_response
  end

  def interpretation
    authorize @scale_response

    @chart_service = Charts::Srs2ComparisonChartService.new(@scale_response.patient)
    @chart_data = @chart_service.chart_data
    @report_info = @chart_service.report_info

    @hetero_response = ScaleResponse.joins(:psychometric_scale).where(patient: @scale_response.patient).where(psychometric_scales: { code: "SRS2HR" }).order(created_at: :desc).first

    # Verificar se é uma escala SRS-2
    if @scale_response.srs2_scale?
      @interpretation_service = Interpretation::Srs2InterpretationService.new


    end
  end



  def destroy
    authorize @scale_response

    # Fazer destroy da scale_response
    @scale_response.destroy!

    # Cancelar a solicitação correspondente
    @scale_response.scale_request.cancel!

    redirect_to scale_responses_path, notice: "Escala descartada com sucesso. A solicitação foi cancelada."
  rescue StandardError => e
    redirect_to @scale_response, alert: "Erro ao descartar a escala: #{e.message}"
  end
  private

  def set_scale_response
    @scale_response = ScaleResponse.find(params[:id])
  end

  def scale_response_params
    # Permitir respostas para todos os itens (item_1, item_2, etc.) e campos do heterorrelato
    # Quando o usuário envia tudo em branco, não vem a chave :scale_response.
    if params[:scale_response].present?
      permitted_params = params.require(:scale_response).permit(
        :relator_name,
        :relator_relationship,
        answers: {}
      )

      # Converter answers para o formato esperado se necessário
      if permitted_params[:answers].present?
        answers = {}
        permitted_params[:answers].each do |key, value|
          if key.match?(/\Aitem_\d+\z/) && value.present?
            answers[key] = value.to_s  # Manter como string para validação posterior
          end
        end
        permitted_params[:answers] = answers
      else
        permitted_params[:answers] = {}
      end

      permitted_params
    else
      # Se não há parâmetros, retornar hash vazio
      ActionController::Parameters.new(answers: {}).permit!
    end
  end

  def redirect_back_with_alert(message)
    if current_user.account_type == "Patient"
      redirect_to patients_dashboard_path, alert: message
    else
      redirect_to scale_requests_path, alert: message
    end
  end

  def redirect_after_success
    if current_user.account_type == "Patient"
      redirect_to patients_dashboard_path, notice: I18n.t("scale_responses.create.success")
    else
      redirect_to @scale_response, notice: I18n.t("scale_responses.create.success")
    end
  end
end
