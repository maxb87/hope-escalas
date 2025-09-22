# frozen_string_literal: true

module Scoring
  class Psa
    # Calcula resultados padronizados para o PSA
    # answers: { "item_1"=>"1", "item_2"=>"3", ... }
    def self.calculate(answers, scale_version: "1.0", patient_gender: nil, patient_age: nil, patient: nil)
      @patient = patient

      category_scores = calculate_category_scores(answers)
      category_comments = extract_category_comments(answers)
      total_score = calculate_total_score(category_scores)
      interpretation_level = determine_interpretation_level(category_scores, total_score)

      build_result_hash(total_score, interpretation_level, category_scores, category_comments, scale_version, patient)
    end

    private

    # Mapeamento dos itens por categoria
    CATEGORY_ITEMS = {
      "A" => (1..8).to_a,      # Processamento Tátil/Olfativo
      "B" => (9..16).to_a,     # Processamento Vestibular/Proprioceptivo
      "C" => (17..26).to_a,    # Processamento Visual
      "D" => (27..39).to_a,    # Processamento Tátil
      "E" => (40..49).to_a,    # Nível de Atividade
      "F" => (50..60).to_a     # Processamento Auditivo
    }.freeze

    CATEGORY_NAMES = {
      "A" => "Processamento Tátil/Olfativo",
      "B" => "Processamento Vestibular/Proprioceptivo",
      "C" => "Processamento Visual",
      "D" => "Processamento Tátil",
      "E" => "Nível de Atividade",
      "F" => "Processamento Auditivo"
    }.freeze

    # Calcula a pontuação de cada categoria
    def self.calculate_category_scores(answers)
      category_scores = {}

      CATEGORY_ITEMS.each do |category, item_numbers|
        category_total = 0
        answered_items = 0

        item_numbers.each do |item_number|
          answer_key = "item_#{item_number}"
          if answers[answer_key].present?
            category_total += answers[answer_key].to_i
            answered_items += 1
          end
        end

        # Calcular pontuação da categoria
        if answered_items > 0
          average_score = category_total.to_f / answered_items
          category_scores[category] = {
            total: category_total,
            average: average_score.round(2),
            answered_items: answered_items,
            total_items: item_numbers.count,
            completion_rate: (answered_items.to_f / item_numbers.count * 100).round(1),
            name: CATEGORY_NAMES[category],
            interpretation: interpret_category_score(average_score)
          }
        else
          category_scores[category] = {
            total: 0,
            average: 0,
            answered_items: 0,
            total_items: item_numbers.count,
            completion_rate: 0,
            name: CATEGORY_NAMES[category],
            interpretation: "Não respondido"
          }
        end
      end

      category_scores
    end

    # Calcula a pontuação total
    def self.calculate_total_score(category_scores)
      category_scores.values.sum { |category| category[:total] }
    end

    # Interpreta a pontuação de uma categoria baseada na média
    def self.interpret_category_score(average_score)
      case average_score
      when 0...1.5
        "Quase nunca"
      when 1.5...2.5
        "Raramente/Ocasionalmente"
      when 2.5...3.5
        "Ocasionalmente/Frequentemente"
      when 3.5...4.5
        "Frequentemente"
      when 4.5..5.0
        "Quase sempre"
      else
        "Pontuação inválida"
      end
    end

    # Determina o nível de interpretação geral
    def self.determine_interpretation_level(category_scores, total_score)
      # Análise baseada nos padrões de resposta das categorias
      high_scores = category_scores.count { |_, data| data[:average] >= 4.0 }
      low_scores = category_scores.count { |_, data| data[:average] <= 2.0 }

      if high_scores >= 4
        "Padrão de alta responsividade sensorial"
      elsif low_scores >= 4
        "Padrão de baixa responsividade sensorial"
      elsif high_scores >= 2 && low_scores >= 2
        "Padrão misto de responsividade sensorial"
      else
        "Padrão típico de responsividade sensorial"
      end
    end

    # Extrai comentários das categorias
    def self.extract_category_comments(answers)
      comments = {}

      %w[a b c d e f].each do |category|
        comment_key = "comment_category_#{category}"
        if answers[comment_key].present?
          comments[category.upcase] = {
            category: CATEGORY_NAMES[category.upcase],
            comment: answers[comment_key]
          }
        end
      end

      comments
    end

    # Constrói o hash de resultados padronizado
    def self.build_result_hash(total_score, interpretation_level, category_scores, category_comments, scale_version, patient)
      {
        "schema_version" => 1,
        "scale_code" => "PSA",
        "scale_version" => scale_version,
        "computed_at" => Time.current.iso8601,
        "patient_info" => {
          "age" => patient&.age,
          "gender" => patient&.gender
        },
        "metrics" => {
          "raw_score" => total_score,
          "total_possible" => 300 # 60 questões x 5 pontos máximo
        },
        "subscales" => build_subscales_data(category_scores),
        "interpretation" => {
          "level" => interpretation_level,
          "description" => build_interpretation_description(category_scores, total_score)
        },
        "categories" => category_scores,
        "comments" => category_comments
      }
    end

    # Constrói dados das subescalas no formato esperado
    def self.build_subscales_data(category_scores)
      subscales = {}

      category_scores.each do |category, data|
        subscales["category_#{category.downcase}"] = {
          "name" => data[:name],
          "raw_score" => data[:total],
          "average_score" => data[:average],
          "interpretation" => data[:interpretation],
          "completion_rate" => data[:completion_rate]
        }
      end

      subscales
    end

    # Constrói descrição detalhada da interpretação
    def self.build_interpretation_description(category_scores, total_score)
      descriptions = []

      descriptions << "Pontuação total: #{total_score}/300"

      # Destacar categorias com pontuações extremas
      high_categories = category_scores.select { |_, data| data[:average] >= 4.0 }
      low_categories = category_scores.select { |_, data| data[:average] <= 2.0 }

      unless high_categories.empty?
        names = high_categories.map { |_, data| data[:name] }
        descriptions << "Categorias com alta responsividade: #{names.join(', ')}"
      end

      unless low_categories.empty?
        names = low_categories.map { |_, data| data[:name] }
        descriptions << "Categorias com baixa responsividade: #{names.join(', ')}"
      end

      descriptions.join(". ")
    end
  end
end
