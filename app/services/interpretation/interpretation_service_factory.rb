# frozen_string_literal: true

module Interpretation
  class InterpretationServiceFactory
    class UnsupportedScaleError < StandardError; end

    # Mapeamento de códigos de escala para seus serviços de interpretação
    SCALE_SERVICES = {
      "SRS2SR" => Interpretation::Srs2InterpretationService,
      "SRS2HR" => Interpretation::Srs2InterpretationService,
      "PSA" => Interpretation::PsaInterpretationService
    }.freeze

    def self.service_for(scale_response)
      scale_code = scale_response.psychometric_scale.code
      service_class = SCALE_SERVICES[scale_code]

      raise UnsupportedScaleError, "No interpretation service available for scale: #{scale_code}" unless service_class

      service_class
    end

    def self.supports_interpretation?(scale_response)
      scale_code = scale_response.psychometric_scale.code
      SCALE_SERVICES.key?(scale_code)
    end

    def self.supported_scales
      SCALE_SERVICES.keys
    end

    # Método principal para gerar interpretação de qualquer escala suportada
    def self.generate_interpretation(scale_response)
      service_class = service_for(scale_response)

      case scale_response.psychometric_scale.code
      when "SRS2SR", "SRS2HR"
        generate_srs2_interpretation(scale_response, service_class)
      when "PSA"
        generate_psa_interpretation(scale_response, service_class)
      else
        # Template para futuras escalas
        raise UnsupportedScaleError, "Interpretation generation not implemented for: #{scale_response.psychometric_scale.code}"
      end
    end

    private

    def self.generate_srs2_interpretation(scale_response, service_class)
      # Criar adapters usando o serviço SRS-2
      scale_response_adapter = service_class.adapter_for(scale_response)
      hetero_response = service_class.find_hetero_response(scale_response)
      
      # Buscar todos os heterorrelatos para o paciente
      all_hetero_responses = service_class.find_all_hetero_responses(scale_response.patient)

      # Gerar interpretação integrada
      interpretation = service_class.generate_integrated_interpretation(
        scale_response_adapter,
        hetero_response
      )

      # Retornar estrutura padronizada
      {
        scale_response_adapter: scale_response_adapter,
        hetero_response: hetero_response,
        hetero_reports: all_hetero_responses,
        interpretation: interpretation,
        scale_type: :srs2
      }
    end

    def self.generate_psa_interpretation(scale_response, service_class)
      # Criar adapter usando o serviço PSA
      scale_response_adapter = service_class.adapter_for(scale_response)
      
      # PSA não possui heterorrelatos
      hetero_response = nil
      all_hetero_responses = []

      # Gerar interpretação integrada
      interpretation = service_class.generate_integrated_interpretation(
        scale_response_adapter
      )

      # Retornar estrutura padronizada
      {
        scale_response_adapter: scale_response_adapter,
        hetero_response: hetero_response,
        hetero_reports: all_hetero_responses,
        interpretation: interpretation,
        scale_type: :psa
      }
    end
  end
end
