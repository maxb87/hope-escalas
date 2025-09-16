#!/usr/bin/env ruby

# Read the original file
content = File.read('app/services/scoring/srs2.rb')

# Replace the calculate method
old_calculate = <<~OLD
    def self.calculate(answers, scale_version: "2.0", patient_gender: nil, patient_age: nil, scale_type: nil)
      raw_score = calculate_raw_score(answers)
      level = determine_interpretation_level(raw_score)
      subscale_scores = calculate_subscale_scores(answers)
      lookup_results = calculate_lookup_results(raw_score, subscale_scores, patient_gender, patient_age, scale_type)

      build_result_hash(raw_score, level, subscale_scores, lookup_results, scale_version)
    end
OLD

new_calculate = <<~NEW
    def self.calculate(answers, scale_version: "2.0", patient_gender: nil, patient_age: nil, scale_type: nil)
      raw_score = calculate_raw_score(answers)
      subscale_scores = calculate_subscale_scores(answers)
      lookup_results = calculate_lookup_results(raw_score, subscale_scores, patient_gender, patient_age, scale_type)
      
      # Use t-score for interpretation level determination
      t_score = lookup_results[:total][:t_score]
      level = determine_interpretation_level(t_score)

      build_result_hash(raw_score, level, subscale_scores, lookup_results, scale_version)
    end
NEW

# Replace the determine_interpretation_level method
old_interpretation = <<~OLD
    # Determina o nível de interpretação baseado no raw score
    def self.determine_interpretation_level(raw_score)
      case raw_score
      when 0..25 then "Normal"
      when 26..55 then "Leve"
      when 56..85 then "Moderado"
      when 86..195 then "Severo"
      else "Pontuação inválida"
      end
    end
OLD

new_interpretation = <<~NEW
    # Determina o nível de interpretação baseado no t-score
    def self.determine_interpretation_level(t_score)
      return "Pontuação inválida" unless t_score

      case t_score
      when 0..54 then "normal"
      when 55..64 then "leve"
      when 65..74 then "moderado"
      when 75..100 then "severo"
      else "Pontuação inválida"
      end
    end
NEW

# Apply the replacements
content = content.gsub(old_calculate.strip, new_calculate.strip)
content = content.gsub(old_interpretation.strip, new_interpretation.strip)

# Write the updated content back to the file
File.write('app/services/scoring/srs2.rb', content)

puts "Successfully updated SRS-2 scoring service to use t-scores for interpretation!"
