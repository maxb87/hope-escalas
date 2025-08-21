class DashboardsController < ApplicationController
  def show
    authorize :dashboards, :show?
    account = current_user.account
    if account.is_a?(Professional) || current_user.email == "admin@admin.com"
      redirect_to professionals_dashboard_path and return
    elsif account.is_a?(Patient)
      redirect_to patients_dashboard_path and return
    else
      redirect_to root_path, alert: "Conta sem perfil associado." and return
    end
  end

  def professionals
    authorize :dashboards, :professionals?
    @patients = policy_scope(Patient).order(:full_name)

    # Otimizar queries para evitar N+1
    # Buscar todas as contagens em queries únicas
    patient_ids = @patients.pluck(:id)

    completed_counts = ScaleResponse.where(patient_id: patient_ids)
                                   .group(:patient_id)
                                   .count

    pending_counts = ScaleRequest.where(patient_id: patient_ids, status: "pending")
                                 .group(:patient_id)
                                 .count

    # Combinar dados de forma eficiente
    @patients_with_counts = @patients.map do |patient|
      {
        patient: patient,
        completed_count: completed_counts[patient.id] || 0,
        pending_count: pending_counts[patient.id] || 0
      }
    end
  end

  def patients
    authorize :dashboards, :patients?
    @patient = current_user.account if current_user.account.is_a?(Patient)
    if @patient
      @pending_requests = ScaleRequest.where(patient: @patient, status: "pending")
                                      .includes(:psychometric_scale, :professional)
                                      .order(requested_at: :desc)
      @completed_responses = ScaleResponse.where(patient: @patient)
                                          .includes(:psychometric_scale)
                                          .order(completed_at: :desc)

      # Contadores para notificações
      @pending_count = @pending_requests.count
      @completed_count = @completed_responses.count
    end
  end
end
