class ScaleResponsesController < ApplicationController
  before_action :set_scale_response, only: [ :show ]

  def new
    @scale_request = ScaleRequest.find(params[:scale_request_id])
    authorize @scale_request, :respond?

    # Verificação adicional: se já existe resposta, redirecionar
    if @scale_request.scale_response.present?
      redirect_to patients_dashboard_path,
                  alert: I18n.t("scale_responses.errors.already_completed")
      return
    end

    # Verificação adicional: se não está pendente, redirecionar
    unless @scale_request.pending?
      redirect_to patients_dashboard_path,
                  alert: I18n.t("scale_responses.errors.not_pending")
      return
    end

    @scale_response = ScaleResponse.new
    @scale_response.scale_request = @scale_request
    @scale_response.patient = current_user.account
    @scale_response.psychometric_scale = @scale_request.psychometric_scale

    @scale_items = @scale_request.psychometric_scale.scale_items.ordered
    authorize @scale_response
  end

  def create
    @scale_request = ScaleRequest.find(params[:scale_request_id])
    authorize @scale_request, :respond?

    # Verificação adicional: se já existe resposta, redirecionar
    if @scale_request.scale_response.present?
      redirect_to patients_dashboard_path,
                  alert: I18n.t("scale_responses.errors.already_completed")
      return
    end

    # Verificação adicional: se não está pendente, redirecionar
    unless @scale_request.pending?
      redirect_to patients_dashboard_path,
                  alert: I18n.t("scale_responses.errors.not_pending")
      return
    end

    @scale_response = ScaleResponse.new(scale_response_params)
    @scale_response.scale_request = @scale_request
    @scale_response.patient = current_user.account
    @scale_response.psychometric_scale = @scale_request.psychometric_scale

    authorize @scale_response

    if @scale_response.save
      @scale_request.complete!
      if current_user.account_type == "Patient"
        redirect_to patients_dashboard_path, notice: I18n.t("scale_responses.create.success")
      else
        redirect_to @scale_response, notice: I18n.t("scale_responses.create.success")
      end
    else
      @scale_items = @scale_request.psychometric_scale.scale_items.ordered
      flash.now[:alert] = I18n.t("errors.messages.not_saved", count: @scale_response.errors.count, resource: @scale_response.class.model_name.human.downcase)
      render :new, status: :unprocessable_entity
    end
  end

  def show
    authorize @scale_response
  end

  private

  def set_scale_response
    @scale_response = ScaleResponse.find(params[:id])
  end

  def scale_response_params
    # Permitir respostas para todos os itens (item_1, item_2, etc.)
    # Quando o usuário envia tudo em branco, não vem a chave :scale_response.
    if params[:scale_response].present?
      permitted_params = params.require(:scale_response).permit(answers: {})

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
end
