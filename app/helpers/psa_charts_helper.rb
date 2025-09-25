# frozen_string_literal: true

module PsaChartsHelper
  # Gera o HTML para o gráfico de radar das subescalas PSA
  def psa_subscales_radar_chart(scale_response, options = {})
    chart_data = psa_subscales_chart_data(scale_response)
    return content_tag(:p, "Dados das subescalas não disponíveis.", class: "text-muted") if chart_data.empty?

    container_id = options[:id] || "psaSubscalesChart"
    height = options[:height] || "400px"
    max_width = options[:max_width] || nil

    style = "height: #{height};"
    style += " max-width: #{max_width};" if max_width

    content_tag :div, class: "psa-chart-container", style: style do
      content_tag :canvas, "", 
        id: container_id,
        width: "400", 
        height: "400",
        data: {
          chart_data: chart_data.to_json,
          chart_options: psa_radar_chart_options("Perfil Sensorial - Subescalas").to_json
        }
    end
  end

  # Gera o HTML para o gráfico de categorias PSA (box plot simulado)
  def psa_categories_boxplot_chart(scale_response, options = {})
    chart_data = psa_categories_boxplot_data(scale_response)
    return content_tag(:p, "Dados das categorias não disponíveis.", class: "text-muted") if chart_data.empty?

    container_id = options[:id] || "psaCategoriesBoxplot"
    height = options[:height] || "400px"
    max_width = options[:max_width] || nil

    style = "height: #{height};"
    style += " max-width: #{max_width};" if max_width

    content_tag :div, class: "psa-chart-container", style: style do
      content_tag :canvas, "", 
        id: container_id,
        width: "600", 
        height: "400",
        data: {
          chart_data: chart_data.to_json,
          chart_options: psa_boxplot_chart_options("Perfil Sensorial - Categorias (Box Plot)").to_json
        }
    end
  end

  # Gera dados para gráfico de radar das subescalas
  def psa_subscales_chart_data(scale_response)
    return {} unless scale_response.results.present? && scale_response.results["subscale"].present?

    subscales = scale_response.results["subscale"]
    
    # Dados do paciente
    patient_data = {
      labels: [],
      datasets: [{
        label: 'Paciente',
        data: [],
        backgroundColor: 'rgba(128, 0, 128, 0.2)',
        borderColor: 'rgba(128, 0, 128, 1)',
        borderWidth: 2,
        pointBackgroundColor: 'rgba(128, 0, 128, 1)',
        pointBorderColor: '#fff',
        pointHoverBackgroundColor: '#fff',
        pointHoverBorderColor: 'rgba(128, 0, 128, 1)'
      }]
    }

    # Dados de referência (valores normais)
    reference_data = {
      labels: [],
      datasets: [{
        label: 'Referência',
        data: [],
        backgroundColor: 'rgba(0, 191, 255, 0.2)',
        borderColor: 'rgba(0, 191, 255, 1)',
        borderWidth: 2,
        borderDash: [5, 5],
        pointBackgroundColor: 'rgba(0, 191, 255, 1)',
        pointBorderColor: '#fff',
        pointHoverBackgroundColor: '#fff',
        pointHoverBorderColor: 'rgba(0, 191, 255, 1)'
      }]
    }

    # Ordem das subescalas para o gráfico
    subscale_order = ['A', 'B', 'C', 'D', 'E', 'F']
    
    subscale_order.each do |subscale|
      if subscales[subscale].present?
        # Labels (títulos das subescalas)
        patient_data[:labels] << get_subscale_title(subscale)
        reference_data[:labels] << get_subscale_title(subscale)
        
        # Dados do paciente (score normalizado para escala 1-5)
        patient_score = subscales[subscale]["score"].to_f
        patient_average = subscales[subscale]["average"].to_f
        patient_data[:datasets][0][:data] << patient_average
        
        # Dados de referência (valores normais - assumindo média 3.0)
        reference_data[:datasets][0][:data] << 3.0
      end
    end

    {
      patient: patient_data,
      reference: reference_data
    }
  end

  # Gera dados para gráfico de categorias com barras coloridas por nível
  def psa_categories_boxplot_data(scale_response)
    return {} unless scale_response.results.present? && scale_response.results["category"].present?

    # Obter idade do paciente
    patient_age = scale_response.patient&.age || 25 # fallback para idade adulta
    
    categories = scale_response.results["category"]
    
    # Dados do gráfico
    chart_data = {
      labels: [],
      datasets: []
    }

    # Ordem das categorias
    category_order = ['baixo_registro', 'procura_sensacao', 'sensibilidade_sensorial', 'evita_sensacao']
    
    # Dados do paciente (linha)
    patient_data = []
    
    category_order.each do |category|
      if categories[category].present?
        # Label da categoria
        chart_data[:labels] << get_category_title(category)
        
        # Score do paciente
        patient_score = categories[category]["score"].to_f
        patient_data << patient_score
      end
    end

    # Criar datasets para cada nível de referência (uma vez só, não por categoria)
    reference_levels = [
      { label: 'Média Inferior', color: 'rgba(0, 90, 180, 0.3)', border_color: 'rgba(0, 150, 0, 0.3)' },
      { label: 'Abaixo da Média', color: 'rgba(0, 200, 0, 0.3)', border_color: 'rgba(0, 200, 0, 0.3)' },
      { label: 'Média', color: 'rgba(255, 255, 0, 0.3)', border_color: 'rgba(255, 255, 0, 0.3)' },
      { label: 'Acima da Média', color: 'rgba(255, 165, 0, 0.3)', border_color: 'rgba(255, 165, 0, 0.3)' },
      { label: 'Média Superior', color: 'rgba(255, 0, 0, 0.3)', border_color: 'rgba(255, 0, 0, 0.3)' }
    ]

    # Para cada nível, criar barras para todas as categorias
    reference_levels.each_with_index do |level, level_index|
      level_data = []
      
      category_order.each do |category|
        if categories[category].present?
          reference_ranges = get_category_reference_ranges(category, patient_age)
          range = reference_ranges[level_index]
          level_data << range[:max] - range[:min] # Altura da barra para este nível
        end
      end

      chart_data[:datasets] << {
        label: level[:label],
        data: level_data,
        backgroundColor: level[:color],
        borderColor: level[:border_color],
        borderWidth: 1,
        stack: 'reference', # Todas as barras no mesmo stack
        order: 0 # Garantir que sejam renderizadas primeiro (atrás da linha)
      }
    end

    # Dataset do paciente (linha) - adicionado por último para ficar em primeiro plano
    chart_data[:datasets] << {
      label: 'Paciente',
      data: patient_data,
      type: 'line',
      borderColor: 'rgba(80, 80, 80, 1)',
      backgroundColor: 'rgba(80, 80, 80, 1)',
      borderWidth: 4,
      pointRadius: 4,
      pointBackgroundColor: 'rgba(80, 80, 80, 1)',
      pointBorderColor: 'rgba(50, 50, 50, 1)',
      pointBorderWidth: 3,
      fill: false,
      tension: 0,
      yAxisID: 'y',
      order: -1 # Garantir que seja renderizado por último (em primeiro plano)
    }

    chart_data
  end

  # Obtém faixas de referência com cores para uma categoria baseado na idade
  def get_category_reference_ranges(category, age)
    case category
    when 'baixo_registro'
      get_baixo_registro_reference_ranges(age)
    when 'procura_sensacao'
      get_procura_sensacao_reference_ranges(age)
    when 'sensibilidade_sensorial'
      get_sensibilidade_sensorial_reference_ranges(age)
    when 'evita_sensacao'
      get_evita_sensacao_reference_ranges(age)
    else
      get_default_reference_ranges
    end
  end

  # Obtém valores de referência para uma categoria baseado na idade
  def get_category_reference_values(category, age)
    case category
    when 'baixo_registro'
      get_baixo_registro_reference_values(age)
    when 'procura_sensacao'
      get_procura_sensacao_reference_values(age)
    when 'sensibilidade_sensorial'
      get_sensibilidade_sensorial_reference_values(age)
    when 'evita_sensacao'
      get_evita_sensacao_reference_values(age)
    else
      [0, 10, 20, 30, 40, 50, 60, 70, 75] # valores padrão
    end
  end

  # Faixas de referência com cores para Baixo Registro
  def get_baixo_registro_reference_ranges(age)
    if age < 18
      [
        { label: 'Muito menos que a maioria', min: 0, max: 17, color: 'rgba(0, 150, 0, 0.6)', border_color: 'rgba(0, 150, 0, 1)' },
        { label: 'Menos que a maioria', min: 18, max: 25, color: 'rgba(0, 200, 0, 0.6)', border_color: 'rgba(0, 200, 0, 1)' },
        { label: 'Semelhante a maioria', min: 26, max: 39, color: 'rgba(255, 255, 0, 0.6)', border_color: 'rgba(255, 255, 0, 1)' },
        { label: 'Mais que a maioria', min: 40, max: 50, color: 'rgba(255, 165, 0, 0.6)', border_color: 'rgba(255, 165, 0, 1)' },
        { label: 'Muito mais que a maioria', min: 51, max: 75, color: 'rgba(255, 0, 0, 0.6)', border_color: 'rgba(255, 0, 0, 1)' }
      ]
    elsif age >= 18 && age <= 64
      [
        { label: 'Muito menos que a maioria', min: 0, max: 17, color: 'rgba(0, 150, 0, 0.6)', border_color: 'rgba(0, 150, 0, 1)' },
        { label: 'Menos que a maioria', min: 18, max: 22, color: 'rgba(0, 200, 0, 0.6)', border_color: 'rgba(0, 200, 0, 1)' },
        { label: 'Semelhante a maioria', min: 23, max: 34, color: 'rgba(255, 255, 0, 0.6)', border_color: 'rgba(255, 255, 0, 1)' },
        { label: 'Mais que a maioria', min: 35, max: 43, color: 'rgba(255, 165, 0, 0.6)', border_color: 'rgba(255, 165, 0, 1)' },
        { label: 'Muito mais que a maioria', min: 44, max: 75, color: 'rgba(255, 0, 0, 0.6)', border_color: 'rgba(255, 0, 0, 1)' }
      ]
    elsif age >= 65
      [
        { label: 'Muito menos que a maioria', min: 0, max: 18, color: 'rgba(0, 150, 0, 0.6)', border_color: 'rgba(0, 150, 0, 1)' },
        { label: 'Menos que a maioria', min: 19, max: 25, color: 'rgba(0, 200, 0, 0.6)', border_color: 'rgba(0, 200, 0, 1)' },
        { label: 'Semelhante a maioria', min: 26, max: 39, color: 'rgba(255, 255, 0, 0.6)', border_color: 'rgba(255, 255, 0, 1)' },
        { label: 'Mais que a maioria', min: 40, max: 50, color: 'rgba(255, 165, 0, 0.6)', border_color: 'rgba(255, 165, 0, 1)' },
        { label: 'Muito mais que a maioria', min: 51, max: 75, color: 'rgba(255, 0, 0, 0.6)', border_color: 'rgba(255, 0, 0, 1)' }
      ]
    else
      get_default_reference_ranges
    end
  end

  # Valores de referência para Baixo Registro
  def get_baixo_registro_reference_values(age)
    if age < 18
      [0, 18, 26, 40, 51, 75] # Muito menos, Menos, Semelhante, Mais, Muito mais
    elsif age >= 18 && age <= 64
      [0, 18, 23, 35, 44, 75]
    elsif age >= 65
      [0, 19, 26, 40, 51, 75]
    else
      [0, 18, 23, 35, 44, 75] # padrão adulto
    end
  end

  # Faixas de referência com cores para Procura Sensação
  def get_procura_sensacao_reference_ranges(age)
    if age < 18
      [
        { label: 'Muito menos que a maioria', min: 0, max: 26, color: 'rgba(0, 150, 0, 0.6)', border_color: 'rgba(0, 150, 0, 1)' },
        { label: 'Menos que a maioria', min: 27, max: 40, color: 'rgba(0, 200, 0, 0.6)', border_color: 'rgba(0, 200, 0, 1)' },
        { label: 'Semelhante a maioria', min: 41, max: 57, color: 'rgba(255, 255, 0, 0.6)', border_color: 'rgba(255, 255, 0, 1)' },
        { label: 'Mais que a maioria', min: 58, max: 64, color: 'rgba(255, 165, 0, 0.6)', border_color: 'rgba(255, 165, 0, 1)' },
        { label: 'Muito mais que a maioria', min: 65, max: 75, color: 'rgba(255, 0, 0, 0.6)', border_color: 'rgba(255, 0, 0, 1)' }
      ]
    elsif age >= 18 && age <= 64
      [
        { label: 'Muito menos que a maioria', min: 0, max: 34, color: 'rgba(0, 150, 0, 0.6)', border_color: 'rgba(0, 150, 0, 1)' },
        { label: 'Menos que a maioria', min: 35, max: 41, color: 'rgba(0, 200, 0, 0.6)', border_color: 'rgba(0, 200, 0, 1)' },
        { label: 'Semelhante a maioria', min: 42, max: 55, color: 'rgba(255, 255, 0, 0.6)', border_color: 'rgba(255, 255, 0, 1)' },
        { label: 'Mais que a maioria', min: 56, max: 61, color: 'rgba(255, 165, 0, 0.6)', border_color: 'rgba(255, 165, 0, 1)' },
        { label: 'Muito mais que a maioria', min: 62, max: 75, color: 'rgba(255, 0, 0, 0.6)', border_color: 'rgba(255, 0, 0, 1)' }
      ]
    elsif age >= 65
      [
        { label: 'Muito menos que a maioria', min: 0, max: 27, color: 'rgba(0, 150, 0, 0.6)', border_color: 'rgba(0, 150, 0, 1)' },
        { label: 'Menos que a maioria', min: 28, max: 38, color: 'rgba(0, 200, 0, 0.6)', border_color: 'rgba(0, 200, 0, 1)' },
        { label: 'Semelhante a maioria', min: 39, max: 51, color: 'rgba(255, 255, 0, 0.6)', border_color: 'rgba(255, 255, 0, 1)' },
        { label: 'Mais que a maioria', min: 52, max: 62, color: 'rgba(255, 165, 0, 0.6)', border_color: 'rgba(255, 165, 0, 1)' },
        { label: 'Muito mais que a maioria', min: 63, max: 75, color: 'rgba(255, 0, 0, 0.6)', border_color: 'rgba(255, 0, 0, 1)' }
      ]
    else
      get_default_reference_ranges
    end
  end

  # Valores de referência para Procura Sensação
  def get_procura_sensacao_reference_values(age)
    if age < 18
      [0, 27, 41, 58, 65, 75]
    elsif age >= 18 && age <= 64
      [0, 35, 42, 56, 62, 75]
    elsif age >= 65
      [0, 28, 39, 52, 63, 75]
    else
      [0, 35, 42, 56, 62, 75] # padrão adulto
    end
  end

  # Faixas de referência com cores para Sensibilidade Sensorial
  def get_sensibilidade_sensorial_reference_ranges(age)
    if age < 18
      [
        { label: 'Muito menos que a maioria', min: 0, max: 18, color: 'rgba(0, 150, 0, 0.6)', border_color: 'rgba(0, 150, 0, 1)' },
        { label: 'Menos que a maioria', min: 19, max: 24, color: 'rgba(0, 200, 0, 0.6)', border_color: 'rgba(0, 200, 0, 1)' },
        { label: 'Semelhante a maioria', min: 25, max: 39, color: 'rgba(255, 255, 0, 0.6)', border_color: 'rgba(255, 255, 0, 1)' },
        { label: 'Mais que a maioria', min: 40, max: 47, color: 'rgba(255, 165, 0, 0.6)', border_color: 'rgba(255, 165, 0, 1)' },
        { label: 'Muito mais que a maioria', min: 48, max: 75, color: 'rgba(255, 0, 0, 0.6)', border_color: 'rgba(255, 0, 0, 1)' }
      ]
    elsif age >= 18 && age <= 64
      [
        { label: 'Muito menos que a maioria', min: 0, max: 17, color: 'rgba(0, 150, 0, 0.6)', border_color: 'rgba(0, 150, 0, 1)' },
        { label: 'Menos que a maioria', min: 18, max: 24, color: 'rgba(0, 200, 0, 0.6)', border_color: 'rgba(0, 200, 0, 1)' },
        { label: 'Semelhante a maioria', min: 25, max: 40, color: 'rgba(255, 255, 0, 0.6)', border_color: 'rgba(255, 255, 0, 1)' },
        { label: 'Mais que a maioria', min: 41, max: 47, color: 'rgba(255, 165, 0, 0.6)', border_color: 'rgba(255, 165, 0, 1)' },
        { label: 'Muito mais que a maioria', min: 48, max: 75, color: 'rgba(255, 0, 0, 0.6)', border_color: 'rgba(255, 0, 0, 1)' }
      ]
    elsif age >= 65
      [
        { label: 'Muito menos que a maioria', min: 0, max: 17, color: 'rgba(0, 150, 0, 0.6)', border_color: 'rgba(0, 150, 0, 1)' },
        { label: 'Menos que a maioria', min: 18, max: 24, color: 'rgba(0, 200, 0, 0.6)', border_color: 'rgba(0, 200, 0, 1)' },
        { label: 'Semelhante a maioria', min: 25, max: 40, color: 'rgba(255, 255, 0, 0.6)', border_color: 'rgba(255, 255, 0, 1)' },
        { label: 'Mais que a maioria', min: 41, max: 47, color: 'rgba(255, 165, 0, 0.6)', border_color: 'rgba(255, 165, 0, 1)' },
        { label: 'Muito mais que a maioria', min: 48, max: 75, color: 'rgba(255, 0, 0, 0.6)', border_color: 'rgba(255, 0, 0, 1)' }
      ]
    else
      get_default_reference_ranges
    end
  end

  # Valores de referência para Sensibilidade Sensorial
  def get_sensibilidade_sensorial_reference_values(age)
    if age < 18
      [0, 19, 25, 40, 48, 75]
    elsif age >= 18 && age <= 64
      [0, 18, 25, 41, 48, 75]
    elsif age >= 65
      [0, 18, 25, 41, 48, 75]
    else
      [0, 18, 25, 41, 48, 75] # padrão adulto
    end
  end

  # Faixas de referência com cores para Evita Sensação
  def get_evita_sensacao_reference_ranges(age)
    if age < 18
      [
        { label: 'Muito menos que a maioria', min: 0, max: 17, color: 'rgba(0, 150, 0, 0.6)', border_color: 'rgba(0, 150, 0, 1)' },
        { label: 'Menos que a maioria', min: 18, max: 24, color: 'rgba(0, 200, 0, 0.6)', border_color: 'rgba(0, 200, 0, 1)' },
        { label: 'Semelhante a maioria', min: 25, max: 39, color: 'rgba(255, 255, 0, 0.6)', border_color: 'rgba(255, 255, 0, 1)' },
        { label: 'Mais que a maioria', min: 40, max: 47, color: 'rgba(255, 165, 0, 0.6)', border_color: 'rgba(255, 165, 0, 1)' },
        { label: 'Muito mais que a maioria', min: 48, max: 75, color: 'rgba(255, 0, 0, 0.6)', border_color: 'rgba(255, 0, 0, 1)' }
      ]
    elsif age >= 18 && age <= 64
      [
        { label: 'Muito menos que a maioria', min: 0, max: 18, color: 'rgba(0, 150, 0, 0.6)', border_color: 'rgba(0, 150, 0, 1)' },
        { label: 'Menos que a maioria', min: 19, max: 25, color: 'rgba(0, 200, 0, 0.6)', border_color: 'rgba(0, 200, 0, 1)' },
        { label: 'Semelhante a maioria', min: 26, max: 40, color: 'rgba(255, 255, 0, 0.6)', border_color: 'rgba(255, 255, 0, 1)' },
        { label: 'Mais que a maioria', min: 41, max: 48, color: 'rgba(255, 165, 0, 0.6)', border_color: 'rgba(255, 165, 0, 1)' },
        { label: 'Muito mais que a maioria', min: 49, max: 75, color: 'rgba(255, 0, 0, 0.6)', border_color: 'rgba(255, 0, 0, 1)' }
      ]
    elsif age >= 65
      [
        { label: 'Muito menos que a maioria', min: 0, max: 17, color: 'rgba(0, 150, 0, 0.6)', border_color: 'rgba(0, 150, 0, 1)' },
        { label: 'Menos que a maioria', min: 18, max: 24, color: 'rgba(0, 200, 0, 0.6)', border_color: 'rgba(0, 200, 0, 1)' },
        { label: 'Semelhante a maioria', min: 25, max: 41, color: 'rgba(255, 255, 0, 0.6)', border_color: 'rgba(255, 255, 0, 1)' },
        { label: 'Mais que a maioria', min: 42, max: 48, color: 'rgba(255, 165, 0, 0.6)', border_color: 'rgba(255, 165, 0, 1)' },
        { label: 'Muito mais que a maioria', min: 49, max: 75, color: 'rgba(255, 0, 0, 0.6)', border_color: 'rgba(255, 0, 0, 1)' }
      ]
    else
      get_default_reference_ranges
    end
  end

  # Valores de referência para Evita Sensação
  def get_evita_sensacao_reference_values(age)
    if age < 18
      [0, 18, 25, 40, 48, 75]
    elsif age >= 18 && age <= 64
      [0, 19, 26, 41, 49, 75]
    elsif age >= 65
      [0, 18, 25, 42, 49, 75]
    else
      [0, 19, 26, 41, 49, 75] # padrão adulto
    end
  end

  # Faixas de referência padrão
  def get_default_reference_ranges
    [
      { label: 'Muito menos que a maioria', min: 0, max: 15, color: 'rgba(0, 150, 0, 0.6)', border_color: 'rgba(0, 150, 0, 1)' },
      { label: 'Menos que a maioria', min: 16, max: 30, color: 'rgba(0, 200, 0, 0.6)', border_color: 'rgba(0, 200, 0, 1)' },
      { label: 'Semelhante a maioria', min: 31, max: 45, color: 'rgba(255, 255, 0, 0.6)', border_color: 'rgba(255, 255, 0, 1)' },
      { label: 'Mais que a maioria', min: 46, max: 60, color: 'rgba(255, 165, 0, 0.6)', border_color: 'rgba(255, 165, 0, 1)' },
      { label: 'Muito mais que a maioria', min: 61, max: 75, color: 'rgba(255, 0, 0, 0.6)', border_color: 'rgba(255, 0, 0, 1)' }
    ]
  end

  # Gera configuração do gráfico de radar
  def psa_radar_chart_options(title)
    {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        title: {
          display: true,
          text: title,
          font: {
            size: 16,
            weight: 'bold'
          }
        },
        legend: {
          display: true,
          position: 'bottom'
        }
      },
      scales: {
        r: {
          beginAtZero: true,
          min: 1,
          max: 5,
          ticks: {
            stepSize: 1,
            callback: "function(value) { return value; }"
          },
          grid: {
            color: 'rgba(0, 0, 0, 0.1)'
          },
          angleLines: {
            color: 'rgba(0, 0, 0, 0.1)'
          }
        }
      }
    }
  end

  # Gera configuração do gráfico de categorias com barras coloridas
  def psa_boxplot_chart_options(title)
    {
      responsive: true,
      maintainAspectRatio: false,
      plugins: {
        title: {
          display: true,
          text: title,
          font: {
            size: 16,
            weight: 'bold'
          }
        },
        legend: {
          display: true,
          position: 'bottom',
          maxHeight: 60,
          labels: {
            usePointStyle: true,
            padding: 15,
            boxWidth: 12,
            boxHeight: 12,
            font: {
              size: 11
            }
          }
        },
        tooltip: {
          mode: 'index',
          intersect: false,
          callbacks: {
            title: "function(context) { return context[0].label; }",
            label: "function(context) { 
              if (context.dataset.label === 'Score do Paciente') {
                return 'Score do Paciente: ' + context.parsed.y;
              } else {
                return context.dataset.label + ': ' + context.parsed.y;
              }
            }"
          }
        }
      },
      scales: {
        y: {
          beginAtZero: true,
          max: 75,
          title: {
            display: true,
            text: 'Score'
          },
          grid: {
            color: 'rgba(0, 0, 0, 0.1)'
          }
        },
        x: {
          stacked: true,
          title: {
            display: true,
            text: 'Categorias'
          },
          grid: {
            display: false
          }
        }
      },
      interaction: {
        mode: 'index',
        intersect: false
      }
    }
  end

  # Títulos das subescalas
  def get_subscale_title(subscale)
    subscale_titles = {
      'A' => 'Processamento Tátil/Olfativo',
      'B' => 'Processamento Vestibular/Proprioceptivo',
      'C' => 'Processamento Visual',
      'D' => 'Processamento Tátil',
      'E' => 'Nível de Atividade',
      'F' => 'Processamento Auditivo'
    }
    subscale_titles[subscale] || subscale
  end

  # Títulos das categorias
  def get_category_title(category)
    category_titles = {
      'baixo_registro' => 'Baixo Registro',
      'procura_sensacao' => 'Procura Sensação',
      'sensibilidade_sensorial' => 'Sensibilidade Sensorial',
      'evita_sensacao' => 'Evita Sensação'
    }
    category_titles[category] || category
  end
end
