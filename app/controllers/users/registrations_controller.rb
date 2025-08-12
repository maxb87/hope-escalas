class Users::RegistrationsController < Devise::RegistrationsController
  before_action :authenticate_user!

  # Ensure users can reach edit/update while forced to reset password
  def edit
    super
  end

  def update
    super do |resource|
      if resource.errors.empty? && resource.respond_to?(:force_password_reset) && resource.force_password_reset
        if resource.respond_to?(:saved_change_to_encrypted_password?) && resource.saved_change_to_encrypted_password?
          resource.update_column(:force_password_reset, false)
          bypass_sign_in(resource)
        else
          flash.now[:alert] = I18n.t("devise.passwords.not_changed", default: "A nova senha não foi salva. Verifique os campos e tente novamente.")
        end
      end
    end
  end

  # Devise chama isto para atualizar; aqui ignoramos senha atual só no primeiro login
  def update_resource(resource, params)
    if resource.respond_to?(:force_password_reset) && resource.force_password_reset
      # Devise já envia params filtrados; não há :user aqui. Se for StrongParams, apenas permita os campos.
      permitted = if params.respond_to?(:permit)
        params.permit(:password, :password_confirmation)
      else
        params.respond_to?(:with_indifferent_access) ?
          params.with_indifferent_access.slice(:password, :password_confirmation) :
          { password: params["password"], password_confirmation: params["password_confirmation"] }.compact
      end

      # Exigir presença básica para evitar salvar sem alterar senha
      if permitted[:password].blank? || permitted[:password_confirmation].blank?
        resource.errors.add(:password, :blank)
        resource.errors.add(:password_confirmation, :blank) if permitted[:password_confirmation].blank?
        return false
      end

      # Atribuição explícita seguida de save para garantir persistência
      resource.password = permitted[:password]
      resource.password_confirmation = permitted[:password_confirmation]
      resource.save
    else
      super
    end
  end
end
