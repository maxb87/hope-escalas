class ScaleRequestPolicy < ApplicationPolicy
  class Scope < Scope
    def resolve
      if user.email == "admin@admin.com"
        scope.includes(:patient, :professional, :psychometric_scale).recent
      elsif user.account_type == "Professional"
        scope.where(professional: user.account).includes(:patient, :psychometric_scale).recent
      elsif user.account_type == "Patient"
        scope.where(patient: user.account).includes(:professional, :psychometric_scale).recent
      else
        scope.none
      end
    end
  end

  def index?
    user.email == "admin@admin.com" || user.account_type == "Professional" || user.account_type == "Patient"
  end

  # Permitir autorizar coleções em actions como pending/completed/cancelled
  def pending?
    index?
  end

  def completed?
    index?
  end

  def cancelled?
    index?
  end

  def show?
    user.email == "admin@admin.com" ||
    (user.account_type == "Professional" && record.professional == user.account) ||
    (user.account_type == "Patient" && record.patient == user.account)
  end

  def create?
    user.email == "admin@admin.com" || user.account_type == "Professional"
  end

  def update?
    user.email == "admin@admin.com" ||
    (user.account_type == "Professional" && record.professional == user.account)
  end

  def destroy?
    user.email == "admin@admin.com" ||
    (user.account_type == "Professional" && record.professional == user.account)
  end

  def cancel?
    user.email == "admin@admin.com" ||
    (user.account_type == "Professional" && record.professional == user.account)
  end

  def respond?
    user.account_type == "Patient" && record.patient == user.account && record.pending?
  end
end
