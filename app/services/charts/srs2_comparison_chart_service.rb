# frozen_string_literal: true

module Charts
  class Srs2ComparisonChartService
    # Subescalas SRS-2 em ordem de exibição no gráfico
    SUBSCALES_ORDER = [
      "social_awareness",
      "social_cognition",
      "social_communication",
      "social_motivation",
      "restricted_interests",
      "social_interaction",
      "total"
    ].freeze

    # Mapeamento de códigos para nomes amigáveis
    SUBSCALE_NAMES = {
      "social_awareness" => "Percepção Social",
      "social_cognition" => "Cognição Social",
      "social_communication" => "Comunicação Social",
      "social_motivation" => "Motivação Social",
      "restricted_interests" => "Padrões Restritos/Repetitivos",
      "social_interaction" => "Interação Social Global",
      "total" => "Total"
    }.freeze

    def initialize(patient)
      @patient = patient
    end

    # Retorna dados formatados para Chart.js
    def chart_data
      {
        labels: labels,
        datasets: datasets,
        options: chart_options
      }
    end

    # Verifica se há dados suficientes para gerar o gráfico
    def has_data?
      self_report_data.present? && hetero_report_data.present?
    end

    # Retorna informações sobre os relatórios encontrados
    def report_info
      {
        self_report: self_report_info,
        hetero_report: hetero_report_info
      }
    end

    # Gera o JavaScript para criar o gráfico
    def chart_js_function
      <<~JAVASCRIPT
        // Função para mapear valores T-Score para rótulos de prejuízo
        function impairmentLevelLabel(value) {
          if (value >= 0 && value < 60) return 'Sem prejuízo';
          if (value >= 60 && value < 65) return 'Prejuízo leve';
          if (value >= 65 && value < 75) return 'Prejuízo moderado';
          if (value >= 75) return 'Prejuízo grave';
          return '';
        }

        function createSrs2ComparisonChart(canvas, chartData) {
          console.log('createSrs2ComparisonChart chamada com:', canvas, chartData);
        #{'  '}
          const ctx = canvas.getContext('2d');
          console.log('Contexto 2D obtido:', ctx);
        #{'  '}
          // Destruir gráfico existente se houver
          if (window.srs2Chart) {
            console.log('Destruindo gráfico existente');
            window.srs2Chart.destroy();
          }
        #{'  '}
          try {
            // Configurar opções do gráfico
            const options = #{chart_options.to_json};
        #{'    '}
            // Personalizar a escala à direita para mostrar apenas rótulos interpretativos
            options.scales.y1.ticks.callback = function(value) {
              return impairmentLevelLabel(value);
            };
        #{'    '}
            // Configurar para mostrar exatamente os 4 níveis de prejuízo
            options.scales.y1.ticks.maxTicksLimit = 4;
            options.scales.y1.ticks.stepSize = null;
        #{'    '}
            // Definir valores específicos para os ticks da escala direita
            options.scales.y1.ticks.count = 4;
            options.scales.y1.ticks.includeBounds = false;
        #{'    '}
            // Forçar a exibição dos rótulos nos pontos corretos
            options.scales.y1.afterBuildTicks = function(scale) {
              const maxValue = #{calculated_max_value};
              scale.ticks = [
                { value: 30, label: 'Sem prejuízo' },
                { value: 62, label: 'Prejuízo leve' },
                { value: 70, label: 'Prejuízo moderado' },
                { value: Math.min(maxValue - 5, 85), label: 'Prejuízo grave' }
              ];
            };
        #{'    '}
            window.srs2Chart = new Chart(ctx, {
              type: 'line',
              data: {
                labels: chartData.labels,
                datasets: chartData.datasets
              },
              options: options
            });
            console.log('Gráfico criado com sucesso!', window.srs2Chart);
          } catch (error) {
            console.error('Erro ao criar gráfico:', error);
          }
        }

        // Função para aguardar Chart.js estar disponível
        function waitForChartJS(callback, maxAttempts = 50) {
          let attempts = 0;
        #{'  '}
          function checkChartJS() {
            attempts++;
            console.log(`Tentativa ${attempts} de verificar Chart.js...`);
        #{'    '}
            if (typeof Chart !== 'undefined') {
              console.log('Chart.js encontrado!');
              callback();
            } else if (attempts < maxAttempts) {
              setTimeout(checkChartJS, 100);
            } else {
              console.error('Chart.js não foi carregado após', maxAttempts, 'tentativas');
            }
          }
        #{'  '}
          checkChartJS();
        }

        // Função para inicializar o gráfico
        function initializeChart() {
          console.log('Inicializando gráfico...');
        #{'  '}
          const chartCanvas = document.getElementById('srs2-comparison-chart');
          console.log('Canvas encontrado:', chartCanvas);
        #{'  '}
          if (chartCanvas) {
            console.log('Dataset chartData:', chartCanvas.dataset.chartData);
        #{'    '}
            try {
              const chartData = JSON.parse(chartCanvas.dataset.chartData);
              console.log('Dados do gráfico parseados:', chartData);
              createSrs2ComparisonChart(chartCanvas, chartData);
            } catch (error) {
              console.error('Erro ao parsear dados do gráfico:', error);
            }
          } else {
            console.error('Canvas srs2-comparison-chart não encontrado');
          }
        }

        // Função para inicializar o gráfico com delay e aguardar Chart.js
        function initializeChartWithDelay() {
          setTimeout(function() {
            console.log('Inicializando gráfico com delay...');
            waitForChartJS(initializeChart);
          }, 100);
        }

        // Event listeners
        document.addEventListener('DOMContentLoaded', function() {
          console.log('DOMContentLoaded disparado');
          initializeChartWithDelay();
        });

        document.addEventListener('turbo:load', function() {
          console.log('turbo:load disparado');
          initializeChartWithDelay();
        });

        // Também tentar inicializar imediatamente se o DOM já estiver pronto
        if (document.readyState === 'loading') {
          console.log('DOM ainda carregando...');
        } else {
          console.log('DOM já carregado, inicializando imediatamente...');
          initializeChartWithDelay();
        }

        // Debug adicional - verificar se Chart.js está disponível
        console.log('Chart.js disponível:', typeof Chart !== 'undefined');
        console.log('Chart:', Chart);
      JAVASCRIPT
    end

    private

    attr_reader :patient

    def labels
      SUBSCALES_ORDER.map { |key| SUBSCALE_NAMES[key] }
    end

    def datasets
      [
        self_report_dataset,
        hetero_report_dataset
      ].compact
    end

    def self_report_dataset
      return nil unless self_report_data.present?

      {
        label: "Autorrelato (#{self_report_respondent_name})",
        data: self_report_t_scores,
        borderColor: "#6c757d", # Cinza
        backgroundColor: "rgba(108, 117, 125, 0.1)",
        borderWidth: 3,
        pointBackgroundColor: "#6c757d",
        pointBorderColor: "#6c757d",
        pointRadius: 6,
        pointHoverRadius: 8,
        pointStyle: "circle", # Círculos para autorelato
        tension: 0.1
      }
    end

    def hetero_report_dataset
      return nil unless hetero_report_data.present?

      {
        label: "Heterorrelato (#{hetero_report_respondent_name})",
        data: hetero_report_t_scores,
        borderColor: "#0d6efd", # Azul
        backgroundColor: "rgba(13, 110, 253, 0.1)",
        borderWidth: 3,
        pointBackgroundColor: "#0d6efd",
        pointBorderColor: "#0d6efd",
        pointRadius: 6,
        pointHoverRadius: 8,
        pointStyle: "triangle", # Triângulos para heterorelato
        tension: 0.1
      }
    end

    def self_report_t_scores
      SUBSCALES_ORDER.map do |subscale|
        if subscale == "total"
          self_report_data.dig("metrics", "t_score")
        else
          self_report_data.dig("subscales", subscale, "t_score")
        end
      end
    end

    def hetero_report_t_scores
      SUBSCALES_ORDER.map do |subscale|
        if subscale == "total"
          hetero_report_data.dig("metrics", "t_score")
        else
          hetero_report_data.dig("subscales", subscale, "t_score")
        end
      end
    end

    def chart_options
      {
        responsive: true,
        maintainAspectRatio: false,
        plugins: {
          title: {
            display: true,
            text: "Comparação SRS-2: Autorrelato vs Heterorrelato",
            font: {
              size: 16,
              weight: "bold"
            }
          },
          legend: {
            display: true,
            position: "top"
          },
          annotation: {
            annotations: impairment_zones_annotations
          }
        },
        scales: {
          y: {
            beginAtZero: false,
            min: calculated_min_value,
            max: calculated_max_value,
            title: {
              display: true,
              text: "Escore T"
            },
            grid: {
              color: "rgba(0, 0, 0, 0.1)"
            },
            ticks: {
              stepSize: 5
            }
          },
          y1: {
            type: "linear",
            display: true,
            position: "right",
            title: {
              display: true,
              text: "Níveis de Prejuízo"
            },
            min: calculated_min_value,
            max: calculated_max_value,
            grid: {
              drawOnChartArea: false
            },
            ticks: {
              stepSize: 5
            }
          },
          x: {
            title: {
              display: true,
              text: "Domínio avaliado"
            },
            ticks: {
              maxRotation: 45,
              minRotation: 0
            }
          }
        }
      }
    end

    # Define as zonas de prejuízo coloridas
    def impairment_zones_annotations
      max_value = calculated_max_value

      {
        no_impairment: {
          type: "box",
          yMin: 0,
          yMax: 60,
          backgroundColor: "rgba(40, 167, 69, 0.3)",
          borderColor: "rgba(40, 167, 69, 0.3)",
          borderWidth: 0,
          drawTime: "beforeDraw"
        },
        mild_impairment: {
          type: "box",
          yMin: 60,
          yMax: 65,
          backgroundColor: "rgba(255, 193, 7, 0.3)",
          borderColor: "rgba(255, 193, 7, 0.3)",
          borderWidth: 0,
          drawTime: "beforeDraw"
        },
        moderate_impairment: {
          type: "box",
          yMin: 65,
          yMax: 75,
          backgroundColor: "rgba(253, 126, 20, 0.3)",
          borderColor: "rgba(253, 126, 20, 0.3)",
          borderWidth: 0,
          drawTime: "beforeDraw"
        },
        severe_impairment: {
          type: "box",
          yMin: 75,
          yMax: max_value,
          backgroundColor: "rgba(220, 53, 69, 0.3)",
          borderColor: "rgba(220, 53, 69, 0.3)",
          borderWidth: 0,
          drawTime: "beforeDraw"
        }
      }
    end

    # Calcula o valor máximo da escala (maior valor + 10, máximo 100)
    def calculated_max_value
      all_values = []

      # Coletar todos os valores T-Score dos datasets
      if self_report_data.present?
        all_values.concat(self_report_t_scores.compact)
      end

      if hetero_report_data.present?
        all_values.concat(hetero_report_t_scores.compact)
      end

      # Retornar o maior valor + 10, com máximo de 100 e mínimo de 90
      max_value = all_values.max || 90
      [ max_value + 10, 90 ].min
      [ max_value + 10, 100 ].max
    end

    # Calcula o valor mínimo da escala (menor valor - 10)
    def calculated_min_value
      all_values = []

      # Coletar todos os valores T-Score dos datasets
      if self_report_data.present?
        all_values.concat(self_report_t_scores.compact)
      end

      if hetero_report_data.present?
        all_values.concat(hetero_report_t_scores.compact)
      end

      # Retornar o menor valor - 10, com mínimo de 10
      min_value = all_values.min || 50
      [ min_value - 10, 10 ].max
    end

    # Busca o autorelato mais recente do paciente
    def self_report_data
      @self_report_data ||= begin
        request = ScaleRequest.joins(:psychometric_scale, :scale_response)
          .where(patient: patient, status: :completed)
          .where(psychometric_scales: { code: "SRS2SR" })
          .order(requested_at: :desc)
          .first

        request&.scale_response&.results
      end
    end

    # Busca o heterorelato mais recente do paciente
    def hetero_report_data
      @hetero_report_data ||= begin
        request = ScaleRequest.joins(:psychometric_scale, :scale_response)
          .where(patient: patient, status: :completed)
          .where(psychometric_scales: { code: "SRS2HR" })
          .order(requested_at: :desc)
          .first

        request&.scale_response&.results
      end
    end

    def self_report_info
      return nil unless self_report_data.present?

      request = ScaleRequest.joins(:psychometric_scale, :scale_response)
        .where(patient: patient, status: :completed)
        .where(psychometric_scales: { code: "SRS2SR" })
        .order(requested_at: :desc)
        .first

      {
        patient_name: patient.full_name,
        requested_at: request.requested_at,
        completed_at: request.scale_response.completed_at
      }
    end

    def hetero_report_info
      return nil unless hetero_report_data.present?

      request = ScaleRequest.joins(:psychometric_scale, :scale_response)
        .where(patient: patient, status: :completed)
        .where(psychometric_scales: { code: "SRS2HR" })
        .order(requested_at: :desc)
        .first

      {
        relator_name: hetero_report_respondent_name,
        requested_at: request.requested_at,
        completed_at: request.scale_response.completed_at
      }
    end

    def self_report_respondent_name
      patient.full_name
    end

    def hetero_report_respondent_name
      # Buscar o ScaleResponse do heterorelato para obter informações do relator
      hetero_response = hetero_report_scale_response

      if hetero_response&.relator_name.present? && hetero_response&.relator_relationship.present?
        "#{hetero_response.relator_name} (#{hetero_response.relator_relationship})"
      elsif hetero_response&.relator_name.present?
        hetero_response.relator_name
      else
        hetero_report_info&.dig(:professional) || "Profissional"
      end
    end

    # Busca o ScaleResponse do heterorelato
    def hetero_report_scale_response
      @hetero_report_scale_response ||= begin
        ScaleRequest.joins(:psychometric_scale, :scale_response)
          .where(patient: patient, status: :completed)
          .where(psychometric_scales: { code: "SRS2HR" })
          .order(requested_at: :desc)
          .first&.scale_response
      end
    end
  end
end
