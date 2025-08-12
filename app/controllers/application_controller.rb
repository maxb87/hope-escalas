class ApplicationController < ActionController::Base
  include Pundit::Authorization
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :enforce_password_reset
  # Rails 7.1+: evitar erro de callbacks em actions inexistentes
  after_action :verify_authorized_unless_index
  after_action :verify_policy_scoped_if_index

  private

  def skip_pundit?
    # Evita callbacks em controllers do Devise e internos do Rails
    devise_controller? || params[:controller].start_with?("rails/")
  end

  def verify_authorized_unless_index
    return if skip_pundit?
    return if action_name == "index"
    verify_authorized
  end

  def verify_policy_scoped_if_index
    return if skip_pundit?
    return unless action_name == "index"
    verify_policy_scoped
  end

  rescue_from Pundit::NotAuthorizedError do
    redirect_to(request.referer.present? ? request.referer : root_path, alert: I18n.t("pundit.default", default: "Você não tem permissão para executar esta ação."))
  end

  def enforce_password_reset
    return unless current_user
    return unless current_user.respond_to?(:force_password_reset)
    return unless current_user.force_password_reset
    # Allow Devise registrations/passwords controllers so the user can change password
    return if devise_controller? && [ "registrations", "passwords" ].include?(controller_name)

    redirect_to edit_user_registration_path, alert: I18n.t("devise.passwords.force_reset", default: "Você precisa redefinir sua senha antes de continuar.")
  end

  def after_sign_in_path_for(resource)
    # Redirecionamento conforme regra de acesso (admin/profissional → lista de pacientes; paciente → perfil)
    account = resource.respond_to?(:account) ? resource.account : nil
    return professionals_dashboard_path if resource.email == "admin@admin.com" || account.is_a?(Professional)
    return patients_dashboard_path if account.is_a?(Patient)
    super
  end
end
