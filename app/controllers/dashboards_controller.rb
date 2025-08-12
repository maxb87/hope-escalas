class DashboardsController < ApplicationController
  def show
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
    @patients = Patient.order(:full_name)
  end

  def patients
    if current_user.account.is_a?(Patient)
      @patient = current_user.account
    else
      redirect_to root_path, alert: "Acesso restrito a pacientes." and return
    end
  end
end
