class ScaleRequestsController < ApplicationController
  before_action :set_scale_request, only: [ :show, :destroy, :cancel ]

  def index
    @active_tab = :pending
    @scale_requests = policy_scope(ScaleRequest)
                        .pending
                        .includes(:patient, :professional, :psychometric_scale, :scale_response)
                        .recent
    load_counters
    authorize ScaleRequest
  end

  def pending
    @active_tab = :pending
    @scale_requests = policy_scope(ScaleRequest)
                        .pending
                        .includes(:patient, :professional, :psychometric_scale, :scale_response)
                        .recent
    load_counters
    authorize ScaleRequest
    render :index
  end

  def completed
    @active_tab = :completed
    @scale_requests = policy_scope(ScaleRequest)
                        .completed
                        .includes(:patient, :professional, :psychometric_scale, :scale_response)
                        .recent
    load_counters
    authorize ScaleRequest
    render :index
  end

  def cancelled
    @active_tab = :cancelled
    @scale_requests = policy_scope(ScaleRequest)
                        .cancelled
                        .includes(:patient, :professional, :psychometric_scale, :scale_response)
                        .recent
    load_counters
    authorize ScaleRequest
    render :index
  end

  def show
    authorize @scale_request
  end

  def new
    @patient = Patient.find(params[:patient_id]) if params[:patient_id]
    @scale_request = ScaleRequest.new
    @scale_request.patient = @patient if @patient
    @psychometric_scales = PsychometricScale.active.ordered
    @patients = policy_scope(Patient).order(:full_name)
    authorize @scale_request
  end

  def create
    @scale_request = ScaleRequest.new(scale_request_params)

    @scale_request.professional = current_user.account
    # status default já é :pending pelo enum; linha abaixo é redundante, mas inofensiva
    @scale_request.status ||= :pending
    authorize @scale_request

    # Verificação adicional antes de salvar
    if !ScaleRequest.can_create_for?(@scale_request.patient, @scale_request.psychometric_scale)
      Rails.logger.warn "[CONTROLLER] Tentativa de criar solicitação bloqueada - verificação adicional"
      @scale_request.errors.add(:base, "Não é possível criar esta solicitação. Verifique se o paciente já não possui uma solicitação ativa desta escala.")
      @psychometric_scales = PsychometricScale.active.ordered
      @patients = policy_scope(Patient).order(:full_name)
      flash.now[:alert] = I18n.t("errors.messages.not_saved", count: @scale_request.errors.count, resource: @scale_request.class.model_name.human.downcase)
      render :new, status: :unprocessable_entity
      return
    end

    if @scale_request.save
      redirect_to pending_scale_requests_path, notice: I18n.t("scale_requests.create.success")
    else
      # Log detalhado quando há erro de validação
      log_patient_scales_status(@scale_request.patient, @scale_request.psychometric_scale) if @scale_request.patient && @scale_request.psychometric_scale

      @psychometric_scales = PsychometricScale.active.ordered
      @patients = policy_scope(Patient).order(:full_name)
      flash.now[:alert] = I18n.t("errors.messages.not_saved", count: @scale_request.errors.count, resource: @scale_request.class.model_name.human.downcase)
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @scale_request
    @scale_request.destroy
    redirect_to pending_scale_requests_path, notice: I18n.t("scale_requests.destroy.success")
  end

  def cancel
    authorize @scale_request
    if @scale_request.cancel!
      # Redirecionar para a lista se veio da lista, caso contrário para show
      redirect_back_or_to(@scale_request, notice: I18n.t("scale_requests.cancel.success"))
    else
      redirect_back_or_to(@scale_request, alert: I18n.t("scale_requests.cancel.failure"))
    end
  end

  private

  def set_scale_request
    @scale_request = ScaleRequest.find(params[:id])
  end

  def scale_request_params
    params.require(:scale_request).permit(:patient_id, :psychometric_scale_id, :notes)
  end

  def load_counters
    base_scope = policy_scope(ScaleRequest)
    @pending_count = base_scope.pending.count
    @completed_count = base_scope.completed.count
    @cancelled_count = base_scope.cancelled.count
  end

  # Método para log detalhado do status das escalas de um paciente
  def log_patient_scales_status(patient, scale)
    return unless patient && scale

    Rails.logger.info "[SCALE_STATUS] === STATUS DETALHADO PARA #{patient.full_name} ==="
    Rails.logger.info "[SCALE_STATUS] Escala sendo solicitada: #{scale.name} (#{scale.code})"

    # Verificar todas as solicitações existentes
    all_requests = patient.scale_requests.joins(:psychometric_scale)
                          .includes(:psychometric_scale, :scale_response)

    Rails.logger.info "[SCALE_STATUS] Total de solicitações: #{all_requests.count}"

    all_requests.each do |req|
      status_info = "ID: #{req.id}, Escala: #{req.psychometric_scale.code}, Status: #{req.status}"
      status_info += ", Tem resposta: #{req.scale_response.present?}" if req.scale_response.present?
      Rails.logger.info "[SCALE_STATUS] - #{status_info}"
    end

    # Verificar especificamente SRS-2
    if scale.code.in?([ "SRS2SR", "SRS2HR" ])
      srs2_requests = all_requests.where(psychometric_scales: { code: scale.code })
                                 .where(status: [ :pending, :completed ])

      Rails.logger.info "[SCALE_STATUS] Solicitações #{scale.code} ativas: #{srs2_requests.count}"
      Rails.logger.info "[SCALE_STATUS] Métodos do paciente:"
      Rails.logger.info "[SCALE_STATUS] - has_active_srs2_self_report?: #{patient.has_active_srs2_self_report?}"
      Rails.logger.info "[SCALE_STATUS] - has_active_srs2_hetero_report?: #{patient.has_active_srs2_hetero_report?}"
      Rails.logger.info "[SCALE_STATUS] - can_receive_srs2_self_report?: #{patient.can_receive_srs2_self_report?}"
      Rails.logger.info "[SCALE_STATUS] - can_receive_srs2_hetero_report?: #{patient.can_receive_srs2_hetero_report?}"
    end

    Rails.logger.info "[SCALE_STATUS] === FIM STATUS DETALHADO ==="
  end
end
