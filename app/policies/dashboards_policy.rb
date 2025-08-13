class DashboardsPolicy < ApplicationPolicy
  def show?
    user.present?
  end

  def professionals?
    admin_email? || professional?
  end

  def patients?
    patient?
  end
end
