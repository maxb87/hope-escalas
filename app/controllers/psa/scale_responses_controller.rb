class Psa::ScaleResponsesController < ApplicationController
  include ChartsHelper

  before_action :set_scale_response, only: [ :show, :destroy ]
  before_action :ensure_psa_scale, only: [ :show, :destroy ]

  def show
    authorize @scale_response
    
    # Verificar se a escala suporta interpretação e gerar dados necessários
    if Interpretation::InterpretationServiceFactory.supports_interpretation?(@scale_response)
      begin
        # Gerar interpretação usando o factory
        interpretation_data = Interpretation::InterpretationServiceFactory.generate_interpretation(@scale_response)

        # Extrair dados para as variáveis de instância
        @scale_response_adapter = interpretation_data[:scale_response_adapter]
        @interpretation = interpretation_data[:interpretation]
        @scale_type = interpretation_data[:scale_type]

        # Gerar dados específicos baseados no tipo de escala
        generate_scale_specific_data

      rescue Interpretation::InterpretationServiceFactory::UnsupportedScaleError => e
        # Se houver erro, definir variáveis vazias para evitar erros na view
        @scale_response_adapter = nil
        @interpretation = nil
        @scale_type = nil
        @chart_service = nil
        @chart_data = nil
        @report_info = nil
      end
    else
      # Se não suporta interpretação, definir variáveis vazias
      @scale_response_adapter = nil
      @interpretation = nil
      @scale_type = nil
      @chart_service = nil
      @chart_data = nil
      @report_info = nil
    end
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

    # Verificar se é uma escala PSA
    unless @scale_request.psychometric_scale.code == "PSA"
      redirect_back_with_alert("Esta rota é específica para escalas PSA")
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

    # Verificar se é uma escala PSA
    unless @scale_request.psychometric_scale.code == "PSA"
      redirect_back_with_alert("Esta rota é específica para escalas PSA")
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

  def destroy
    authorize @scale_response

    # Fazer destroy da scale_response
    @scale_response.destroy!

    # Cancelar a solicitação correspondente
    @scale_response.scale_request.cancel!

    redirect_to scale_responses_path, notice: "Escala PSA descartada com sucesso. A solicitação foi cancelada."
  rescue StandardError => e
    Rails.logger.error "Erro ao descartar escala PSA: #{e.message}"
    redirect_to psa_scale_response_path(@scale_response), alert: "Erro ao descartar escala: #{e.message}"
  end

  private

  def set_scale_response
    @scale_response = ScaleResponse.find(params[:id])
  end

  def ensure_psa_scale
    unless @scale_response.psa_scale?
      redirect_to scale_response_path(@scale_response), alert: "Esta rota é específica para escalas PSA"
    end
  end

  def generate_scale_specific_data
    case @scale_type
    when :psa
      generate_psa_chart_data
      # Futuras escalas podem ser adicionadas aqui
      # when :another_scale
      #   generate_another_scale_data
    end
  end

  def generate_psa_chart_data
    # PSA não possui heterorrelatos, então não há dados de comparação
    @chart_service = nil
    @chart_data = nil
    @report_info = nil
  end

  def scale_response_params
    # Permitir respostas para todos os itens (item_1, item_2, etc.) e comentários por subescala
    # Quando o usuário envia tudo em branco, não vem a chave :scale_response.
    if params[:scale_response].present?
      permitted_params = params.require(:scale_response).permit(
        :scale_request_id,
        answers: {}
      )

      # Converter answers para o formato esperado se necessário
      if permitted_params[:answers].present?
        answers = {}
        subscale_comments = {}
        
        permitted_params[:answers].each do |key, value|
          if key.match?(/\Aitem_\d+\z/) && value.present?
            answers[key] = value.to_s  # Manter como string para validação posterior
          elsif key == "subscale_comments" && value.is_a?(Hash)
            # Processar comentários por subescala
            value.each do |subscale, comment|
              if comment.present?
                subscale_comments[subscale.to_s] = comment.to_s
              end
            end
          end
        end
        
        # Adicionar comentários por subescala se existirem
        answers["subscale_comments"] = subscale_comments if subscale_comments.any?
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
      redirect_to psa_scale_response_path(@scale_response), notice: I18n.t("scale_responses.create.success")
    end
  end
end
