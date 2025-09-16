#!/usr/bin/env ruby

# Read the file
lines = File.readlines('app/services/scoring/srs2.rb')

# Fix the indentation of the determine_interpretation_level method
# Find the start of the method
start_index = nil
lines.each_with_index do |line, index|
  if line.strip.start_with?('# Determina o nível de interpretação baseado no t-score')
    start_index = index
    break
  end
end

if start_index
  # Fix indentation for the method and its contents
  (start_index..start_index + 10).each do |i|
    if i < lines.length
      line = lines[i]
      # Remove existing indentation and add proper indentation
      trimmed = line.lstrip
      if trimmed.start_with?('#') || trimmed.start_with?('def ') || trimmed.start_with?('end')
        lines[i] = "    #{trimmed}"
      elsif trimmed.start_with?('return ') || trimmed.start_with?('case ') || trimmed.start_with?('when ') || trimmed.start_with?('else')
        lines[i] = "      #{trimmed}"
      end
    end
  end
  
  # Write back to file
  File.write('app/services/scoring/srs2.rb', lines.join(''))
  puts "Fixed indentation!"
else
  puts "Could not find the method"
end
