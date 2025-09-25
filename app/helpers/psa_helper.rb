# frozen_string_literal: true

module PsaHelper
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
