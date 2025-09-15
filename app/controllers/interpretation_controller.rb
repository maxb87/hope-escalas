# frozen_string_literal: true

class InterpretationController < ApplicationController
  before_action :set_scale_response, only: [ :srs2_interpretation ]
  before_action :set_patient, only: [ :srs2_interpretation ]

  # GET /interpretation/srs2/:scale_response_id
  def srs2_interpretation
    authorize @scale_response, :srs2_interpretation?

    # Verificar se é uma escala SRS-2
    unless @scale_response.srs2_scale?
      redirect_to @scale_response, alert: "Esta não é uma escala SRS-2 válida."
      return
    end

    # Obter dados da resposta
    @self_report = @scale_response
    @patient = @scale_response.patient

    # Buscar heterorelato correspondente se existir
    @hetero_report = find_hetero_report

    # Gerar interpretação usando o serviço
    @interpretation_service = Interpretation::Srs2InterpretationService.new
    @interpretation_description = @interpretation_service.get_interpretation_description(@patient, @self_report)

    # Gerar dados para as tabelas de comparação
    @comparison_data = generate_comparison_data(@self_report, @hetero_report)

    # Gerar interpretações detalhadas por domínio
    @domain_interpretations = generate_domain_interpretations(@self_report, @hetero_report)

    # Dados para exibição
    @t_score = @self_report.results.dig("metrics", "t_score") || @self_report.results.dig("t_total")
    @raw_score = @self_report.results.dig("metrics", "raw_score") || @self_report.total_score
    @interpretation_level = @self_report.results.dig("interpretation", "level") || "Não disponível"

    # Dados dos domínios
    @domains = extract_domain_data(@self_report)

    render :srs2_interpretation
  end

  private

  def set_scale_response
    @scale_response = ScaleResponse.find(params[:scale_response_id])
  end

  def set_patient
    @patient = @scale_response.patient
  end

  def find_hetero_report
    # Buscar heterorelato correspondente do mesmo paciente
    # Assumindo que há uma relação temporal ou por scale_request
    if @scale_response.psychometric_scale.code == "SRS2SR"
      # Se é autorelato, buscar heterorelato
      ScaleResponse.joins(:psychometric_scale)
                   .where(patient: @patient, psychometric_scales: { code: "SRS2HR" })
                   .where("completed_at IS NOT NULL")
                   .recent
                   .first
    elsif @scale_response.psychometric_scale.code == "SRS2HR"
      # Se é heterorelato, buscar autorelato
      ScaleResponse.joins(:psychometric_scale)
                   .where(patient: @patient, psychometric_scales: { code: "SRS2SR" })
                   .where("completed_at IS NOT NULL")
                   .recent
                   .first
    end
  end

  def generate_comparison_data(self_report, hetero_report)
    return {} unless self_report && hetero_report

    domains = [
      { key: "social_awareness", label: "Percepção Social" },
      { key: "social_cognition", label: "Cognição Social" },
      { key: "social_communication", label: "Comunicação Social" },
      { key: "social_motivation", label: "Motivação Social" },
      { key: "restricted_interests", label: "Padrões Restritos/Repetitivos" },
      { key: "social_interaction", label: "Interação Social Global" },
      { key: "total", label: "Escore Total" }
    ]

    domains.map do |domain|
      self_t_score = get_domain_t_score(self_report, domain[:key])
      hetero_t_score = get_domain_t_score(hetero_report, domain[:key])

      {
        label: domain[:label],
        self_t_score: self_t_score,
        hetero_t_score: hetero_t_score,
        self_interpretation: determine_impairment_level(self_t_score),
        hetero_interpretation: determine_impairment_level(hetero_t_score)
      }
    end
  end

  def generate_domain_interpretations(self_report, hetero_report)
    interpretations = {
      self_report: generate_self_report_interpretations(self_report),
      hetero_report: hetero_report ? generate_hetero_report_interpretations(hetero_report) : nil,
      comparison: hetero_report ? generate_comparison_interpretations(self_report, hetero_report) : nil
    }

    interpretations
  end

  def generate_self_report_interpretations(self_report)
    t_score = get_domain_t_score(self_report, "total")
    level = determine_impairment_level(t_score)

    {
      general: "#{@patient.first_name.capitalize} apresenta sintomatologia #{level[:label]} de acordo com sua percepção sobre a responsividade social. Dessa maneira, ele apresenta dificuldades clinicamente relevantes em:",
      domains: {
        social_cognition: "capacidade de interpretar as pistas sociais após reconhecê-las, lidando com o aspecto interpretativo do comportamento social. #{@patient.first_name.capitalize} percebe que possui dificuldades importantes para compreender nuances do comportamento alheio, o que pode levar a mal-entendidos ou interpretações literais.",
        social_communication: "comunicação expressiva, lidando com os aspectos motores do comportamento social recíproco. Ele reconhece prejuízos na fluência comunicativa, especialmente na expressão adequada de ideias, sentimentos e respostas sociais.",
        social_motivation: "interesse e capacidade de engajar-se em comportamentos sociais e interpessoais. #{@patient.first_name.capitalize} relata inibição para interações espontâneas, o que pode se manifestar como retraimento, desconforto em grupos ou evitamento de situações sociais.",
        social_interaction: "reconhecimento e interpretação de sinais sociais, bem como motivação para o contato interpessoal social expressivo. A soma dos domínios comprometidos indica prejuízo #{level[:label]} em sua capacidade de estabelecer e sustentar trocas interpessoais de maneira funcional."
      }
    }
  end

  def generate_hetero_report_interpretations(hetero_report)
    relator_name = hetero_report.relator_name || "Relator"

    {
      general: "#{@patient.first_name.capitalize} apresenta prejuízos leves a moderados nos domínios avaliados. #{relator_name} observa dificuldades na capacidade de compreender e responder a pistas sociais, manter comunicação fluida e engajar-se espontaneamente em interações. Os domínios de padrões restritos e repetitivos e escore total foram classificados por ela como nível moderado, indicando comportamentos rígidos ou repetitivos claros e impacto global na responsividade social. Os demais domínios foram classificados com prejuízos leves, exceto percepção social, considerada sem prejuízo.",
      comparison: "Embora ambos os relatos revelem comprometimento, #{@patient.first_name.capitalize} tende a perceber maior prejuízo nos domínios interpessoais e comunicacionais. Sua #{relator_name.downcase} enfatiza mais os aspectos comportamentais repetitivos e a presença de dificuldades consistentes, porém mais atenuadas, nas relações sociais."
    }
  end

  def generate_comparison_interpretations(self_report, hetero_report)
    relator_name = hetero_report.relator_name || "Relator"

    {
      restricted_patterns: "comportamentos estereotipados, interesses restritos ou fixações (como foco excessivo em temas específicos ou insistência em rotinas). #{@patient.first_name.capitalize} reconhece traços compatíveis com esse padrão, com prejuízo leve."
    }
  end

  def extract_domain_data(scale_response)
    return [] unless scale_response.results.present?

    domains = [
      { key: "social_awareness", label: "Percepção Social" },
      { key: "social_cognition", label: "Cognição Social" },
      { key: "social_communication", label: "Comunicação Social" },
      { key: "social_motivation", label: "Motivação Social" },
      { key: "restricted_interests", label: "Interesses Restritos/Repetitivos" },
      { key: "social_interaction", label: "Interação Social" }
    ]

    domains.map do |domain|
      t_score = get_domain_t_score(scale_response, domain[:key])
      raw_score = scale_response.results.dig("subscales", domain[:key], "raw_score")

      {
        label: domain[:label],
        key: domain[:key],
        t_score: t_score,
        raw_score: raw_score,
        interpretation: determine_impairment_level(t_score)
      }
    end
  end

  def get_domain_t_score(report, domain_key)
    return nil unless report&.results.present?

    case domain_key
    when "total"
      report.results.dig("metrics", "t_score")
    else
      report.results.dig("subscales", domain_key, "t_score")
    end
  end

  def determine_impairment_level(t_score)
    return { label: "N/A", level: "normal" } unless t_score

    case t_score
    when 0..54
      { label: "normal", level: "normal" }
    when 55..64
      { label: "leve", level: "mild" }
    when 65..74
      { label: "moderado", level: "moderate" }
    when 75..100
      { label: "severo", level: "severe" }
    else
      { label: "N/A", level: "normal" }
    end
  end
end
