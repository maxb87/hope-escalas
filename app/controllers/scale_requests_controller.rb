class ScaleRequestsController < ApplicationController
  before_action :set_scale_request, only: [ :show, :destroy, :cancel ]

  def index
    @scale_requests = policy_scope(ScaleRequest)
                        .includes(:patient, :professional, :psychometric_scale, :scale_response)
                        .recent
    load_counters
    authorize ScaleRequest
  end

  def pending
    @scale_requests = policy_scope(ScaleRequest)
                        .pending
                        .includes(:patient, :professional, :psychometric_scale, :scale_response)
                        .recent
    load_counters
    authorize ScaleRequest
    render :index
  end

  def completed
    @scale_requests = policy_scope(ScaleRequest)
                        .completed
                        .includes(:patient, :professional, :psychometric_scale, :scale_response)
                        .recent
    load_counters
    authorize ScaleRequest
    render :index
  end

  def cancelled
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

    if @scale_request.save
      redirect_to @scale_request.patient, notice: I18n.t("scale_requests.create.success")
    else
      @psychometric_scales = PsychometricScale.active.ordered
      @patients = policy_scope(Patient).order(:full_name)
      flash.now[:alert] = I18n.t("errors.messages.not_saved", count: @scale_request.errors.count, resource: @scale_request.class.model_name.human.downcase)
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @scale_request
    @scale_request.destroy
    redirect_to scale_requests_path, notice: I18n.t("scale_requests.destroy.success")
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
    @all_count = base_scope.count
    @pending_count = base_scope.pending.count
    @completed_count = base_scope.completed.count
    @cancelled_count = base_scope.cancelled.count
  end
end
