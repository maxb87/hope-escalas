class Patient < ApplicationRecord
  acts_as_paranoid
  has_one :user, as: :account, dependent: :destroy
  has_many :scale_requests, dependent: :destroy
  has_many :scale_responses, dependent: :destroy

  validates :full_name, presence: true
  validates :email, presence: true
  validates :gender, presence: true, inclusion: { in: %w[male female] }

  def pending_scale_requests_count
    scale_requests.pending.count
  end

  def completed_scale_responses_count
    scale_responses.count
  end

  # Método para contar solicitações em aberto (pendentes + respondidas)
  def open_scale_requests_count
    scale_requests.where(status: [ :pending, :completed ]).count
  end

  # Método para calcular porcentagem de respostas completas
  def completion_percentage
    return 0 if open_scale_requests_count.zero?
    (completed_scale_responses_count.to_f / open_scale_requests_count * 100).round(1)
  end

  # Verifica se o paciente tem autorelato SRS-2 ativo (pendente ou concluído)
  def has_active_srs2_self_report?
    scale_requests.joins(:psychometric_scale)
                  .where(psychometric_scales: { code: "SRS2SR" })
                  .where(status: [ :pending, :completed ])
                  .exists?
  end

  # Verifica se o paciente tem heterorelato SRS-2 ativo (pendente ou concluído)
  def has_active_srs2_hetero_report?
    scale_requests.joins(:psychometric_scale)
                  .where(psychometric_scales: { code: "SRS2HR" })
                  .where(status: [ :pending, :completed ])
                  .exists?
  end

  # Verifica se o paciente pode receber uma nova solicitação de autorelato SRS-2
  def can_receive_srs2_self_report?
    !has_active_srs2_self_report?
  end

  # Verifica se o paciente pode receber uma nova solicitação de heterorelato SRS-2
  def can_receive_srs2_hetero_report?
    !has_active_srs2_hetero_report?
  end

  # Obtém o autorelato SRS-2 ativo (se existir)
  def active_srs2_self_report
    scale_requests.joins(:psychometric_scale)
                  .where(psychometric_scales: { code: "SRS2SR" })
                  .where(status: [ :pending, :completed ])
                  .first
  end

  # Obtém o heterorelato SRS-2 ativo (se existir)
  def active_srs2_hetero_report
    scale_requests.joins(:psychometric_scale)
                  .where(psychometric_scales: { code: "SRS2HR" })
                  .where(status: [ :pending, :completed ])
                  .first
  end

  def age
    return nil if birthday.nil?

    today = Date.current
    age = today.year - birthday.year
    age -= 1 if today < birthday + age.years
    age
  end

  def first_name
    full_name.split(" ").first
  end
end
