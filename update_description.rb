#!/usr/bin/env ruby

# Read the file
content = File.read('app/services/scoring/srs2.rb')

# Replace the get_interpretation_description method
old_description = <<~OLD
    def self.get_interpretation_description(level)
      case level
      when "Normal"
        "Funcionamento social dentro da faixa normal. Habilidades sociais adequadas para a idade."
      when "Leve"
        "Dificuldades leves em habilidades sociais. Pode apresentar algumas limitações sociais sutis."
      when "Moderado"
        "Dificuldades moderadas em habilidades sociais. Limitações sociais mais evidentes que podem impactar o funcionamento."
      when "Severo"
        "Dificuldades severas em habilidades sociais. Limitações significativas que impactam substancialmente o funcionamento social."
      else
        "Interpretação não disponível."
      end
    end
OLD

new_description = <<~NEW
    def self.get_interpretation_description(level)
      case level
      when "normal"
        "Funcionamento social dentro da faixa normal. Habilidades sociais adequadas para a idade."
      when "leve"
        "Dificuldades leves em habilidades sociais. Pode apresentar algumas limitações sociais sutis."
      when "moderado"
        "Dificuldades moderadas em habilidades sociais. Limitações sociais mais evidentes que podem impactar o funcionamento."
      when "severo"
        "Dificuldades severas em habilidades sociais. Limitações significativas que impactam substancialmente o funcionamento social."
      else
        "Interpretação não disponível."
      end
    end
NEW

# Apply the replacement
content = content.gsub(old_description.strip, new_description.strip)

# Write back to file
File.write('app/services/scoring/srs2.rb', content)

puts "Successfully updated get_interpretation_description method!"
