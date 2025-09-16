#!/usr/bin/env ruby

# Read the file
content = File.read('app/services/scoring/srs2.rb')

# Replace the determine_interpretation_level method
old_method = /    # Determina o nível de interpretação baseado no raw score\s*\n    def self\.determine_interpretation_level\(raw_score\)\s*\n      case raw_score\s*\n      when 0\.\.25 then "Normal"\s*\n      when 26\.\.55 then "Leve"\s*\n      when 56\.\.85 then "Moderado"\s*\n      when 86\.\.195 then "Severo"\s*\n      else "Pontuação inválida"\s*\n      end\s*\n    end/

new_method = <<~NEW
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

# Apply the replacement
content = content.gsub(old_method, new_method.strip)

# Write back to file
File.write('app/services/scoring/srs2.rb', content)

puts "Successfully updated determine_interpretation_level method!"
