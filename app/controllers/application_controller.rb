class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  before_action :authenticate_user!
  before_action :enforce_password_reset

  private

  def enforce_password_reset
    return unless current_user
    return unless current_user.respond_to?(:force_password_reset)
    return unless current_user.force_password_reset
    # Allow Devise registrations/passwords controllers so the user can change password
    return if devise_controller? && [ "registrations", "passwords" ].include?(controller_name)

    redirect_to edit_user_registration_path, alert: I18n.t("devise.passwords.force_reset", default: "Você precisa redefinir sua senha antes de continuar.")
  end

  def after_sign_in_path_for(resource)
    stored_location_for(resource) || (defined?(authenticated_root_path) ? authenticated_root_path : root_path)
  end
end
