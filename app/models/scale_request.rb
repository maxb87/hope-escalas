# MVP: Expiração de solicitações desabilitada
# - Solicitações não expiram automaticamente
# - Métodos de expiração comentados mas mantidos para uso futuro
# - Para habilitar: descomente as validações e callbacks relacionados a expires_at
class ScaleRequest < ApplicationRecord
  acts_as_paranoid

  belongs_to :patient
  belongs_to :professional
  belongs_to :psychometric_scale
  has_one :scale_response, dependent: :destroy

  # Status como enum (coluna integer com default 0 na migration)
  enum :status, { pending: 0, completed: 1, expired: 2, cancelled: 3 }, default: :pending

  validates :status, presence: true
  validates :requested_at, presence: true
  # MVP: Expiração desabilitada - solicitações não expiram
  # validates :expires_at, presence: true, if: :pending?
  # validate :expires_at_after_requested_at, if: :expires_at?

  # Validação para impedir múltiplas solicitações ativas da mesma escala por paciente
  validate :unique_active_request_per_patient_and_scale, unless: :cancelled?
  # Validação para impedir múltiplas solicitações de autorelato SRS-2
  validate :unique_srs2_self_report_request, if: :srs2_self_report?, unless: :cancelled?


  scope :recent, -> { order(requested_at: :desc) }
  scope :active, -> { pending }

  # Preencher requested_at antes de validar na criação
  before_validation :set_requested_at, on: :create, unless: :requested_at?
  # MVP: Expiração desabilitada - não define expires_at automaticamente
  # before_create :set_expires_at, unless: :expires_at?

  # MVP: Expiração desabilitada - sempre retorna false
  def expired_by_time?
    # expires_at.present? && expires_at < Time.current
    false
  end

  def can_be_completed?
    pending? && !expired_by_time?
  end

  def complete!
    # Marcar como completa se estiver pendente
    completed! if pending?
  end
  def cancel!
    cancelled! if pending? || completed?
  end

  def expire!
    expired! if pending?
  end

  # Verificar se é uma escala de autorelato SRS-2
  def srs2_self_report?
    psychometric_scale&.code == "SRS2SR"
  end

  # Verificar se é uma escala de heterorelato SRS-2
  def srs2_hetero_report?
    psychometric_scale&.code == "SRS2HR"
  end

  # Métodos de classe para verificar se paciente pode receber solicitações
  def self.can_create_srs2_self_report_for?(patient)
    return false unless patient

    !joins(:psychometric_scale)
      .where(patient: patient)
      .where(psychometric_scales: { code: "SRS2SR" })
      .where(status: [ :pending, :completed ])
      .exists?
  end

  def self.can_create_srs2_hetero_report_for?(patient)
    return false unless patient

    # Agora permite múltiplos heterorrelatos SRS-2 - sempre retorna true
    true
  end

  # Método para verificar se uma solicitação pode ser criada
  def self.can_create_for?(patient, psychometric_scale)
    return false unless patient && psychometric_scale

    case psychometric_scale.code
    when "SRS2SR"
      can_create_srs2_self_report_for?(patient)
    when "SRS2HR"
      can_create_srs2_hetero_report_for?(patient)
    else
      # Para outras escalas, verifica apenas se não há pendentes
      !where(
        patient: patient,
        psychometric_scale: psychometric_scale,
        status: :pending
      ).exists?
    end
  end

  private

  def set_requested_at
    self.requested_at = Time.current
  end

  # MVP: Expiração desabilitada - mantido para uso futuro
  # def set_expires_at
  #   self.expires_at = 7.days.from_now
  # end

  # MVP: Expiração desabilitada - mantido para uso futuro
  # def expires_at_after_requested_at
  #   if expires_at <= requested_at
  #     errors.add(:expires_at, "deve ser posterior à data de solicitação")
  #   end
  # end

  # Validação para impedir múltiplas solicitações ativas da mesma escala por paciente
  def unique_active_request_per_patient_and_scale
    return unless patient_id.present? && psychometric_scale_id.present?

    # Permitir múltiplos heterorrelatos SRS-2
    return if psychometric_scale&.code == "SRS2HR"

    # Buscar solicitações ativas (pendentes) da mesma escala para o mesmo paciente
    existing_requests = ScaleRequest.where(
      patient_id: patient_id,
      psychometric_scale_id: psychometric_scale_id,
      status: :pending
    )

    # Excluir o próprio registro se estiver sendo atualizado
    existing_requests = existing_requests.where.not(id: id) if persisted?

    if existing_requests.exists?
      scale_name = psychometric_scale&.name || "escala selecionada"
      patient_name = patient&.full_name || "paciente selecionado"

      errors.add(:base, I18n.t("activerecord.errors.models.scale_request.attributes.base.duplicate_active_request",
                               scale: scale_name, patient: patient_name))
    end
  end

  # Validação para impedir múltiplas solicitações de autorelato SRS-2
  def unique_srs2_self_report_request
    return unless patient_id.present?

    # Buscar qualquer solicitação de autorelato SRS-2 (pendente ou concluída) para o mesmo paciente
    existing_requests = ScaleRequest.joins(:psychometric_scale)
      .where(
        patient_id: patient_id,
        psychometric_scales: { code: "SRS2SR" }
      )
      .where(status: [ :pending, :completed ])

    # Excluir o próprio registro se estiver sendo atualizado
    existing_requests = existing_requests.where.not(id: id) if persisted?

    if existing_requests.exists?
      patient_name = patient&.full_name || "paciente selecionado"
      scale_name = psychometric_scale&.name || "SRS-2 Autorrelato"

      errors.add(:base, I18n.t("activerecord.errors.models.scale_request.attributes.base.duplicate_srs2_self_report",
                               scale: scale_name, patient: patient_name))
    end
  end

  # Validação removida para permitir múltiplos heterorrelatos SRS-2
  # Agora é possível ter vários heterorrelatos para o mesmo paciente

  # Método removido - não é mais necessário com múltiplos heterorrelatos permitidos

  private
end
