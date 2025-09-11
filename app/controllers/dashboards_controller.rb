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
    # Redirecionar diretamente para a lista de pacientes
    redirect_to patients_path
  end

  def patients
    authorize :dashboards, :patients?
    @patient = current_user.account if current_user.account.is_a?(Patient)
    if @patient
      # Redirecionar diretamente para o perfil do próprio paciente
      redirect_to patient_path(@patient)
    else
      redirect_to root_path, alert: "Paciente não encontrado." and return
    end
  end
end
