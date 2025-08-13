class ScaleRequestsController < ApplicationController
  before_action :set_scale_request, only: [ :show, :destroy, :cancel ]

  def index
    @scale_requests = policy_scope(ScaleRequest).includes(:patient, :professional, :psychometric_scale).recent
  end

  def show
    authorize @scale_request
  end

  def new
    @patient = Patient.find(params[:patient_id]) if params[:patient_id]
    @scale_request = ScaleRequest.new
    @scale_request.patient = @patient if @patient
    @psychometric_scales = PsychometricScale.active.ordered
    authorize @scale_request
  end

  def create
    @scale_request = ScaleRequest.new(scale_request_params)
    @scale_request.professional = current_user.account
    authorize @scale_request

    if @scale_request.save
      redirect_to @scale_request, notice: "Solicitação criada com sucesso."
    else
      @psychometric_scales = PsychometricScale.active.ordered
      render :new, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @scale_request
    @scale_request.destroy
    redirect_to scale_requests_path, notice: "Solicitação cancelada com sucesso."
  end

  def cancel
    authorize @scale_request
    if @scale_request.cancel!
      redirect_to @scale_request, notice: "Solicitação cancelada com sucesso."
    else
      redirect_to @scale_request, alert: "Não foi possível cancelar a solicitação."
    end
  end

  private

  def set_scale_request
    @scale_request = ScaleRequest.find(params[:id])
  end

  def scale_request_params
    params.require(:scale_request).permit(:patient_id, :psychometric_scale_id, :notes)
  end
end
