class DashboardsPolicy < ApplicationPolicy
  def show?
    user.present?
  end

  def professionals?
    user && (user.email == "admin@admin.com" || (user.account_type == "Professional" && user.account_id.present?))
  end

  def patients?
    user && user.account_type == "Patient" && user.account_id.present?
  end
end
