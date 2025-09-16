#!/usr/bin/env ruby

# Read the file line by line
lines = File.readlines('app/services/scoring/srs2.rb')

# Find and replace the calculate method
in_calculate_method = false
calculate_start = nil
calculate_end = nil
level_line = nil

lines.each_with_index do |line, index|
  if line.strip.start_with?('def self.calculate(')
    in_calculate_method = true
    calculate_start = index
  elsif in_calculate_method && line.strip == 'end'
    calculate_end = index
    break
  elsif in_calculate_method && line.strip.start_with?('level = determine_interpretation_level(')
    level_line = index
  end
end

# Replace line 12 (level = determine_interpretation_level(raw_score)) 
# with the new implementation
if level_line
  # Insert new lines
  new_lines = lines.dup
  
  # Replace the level determination line
  new_lines[level_line] = "      subscale_scores = calculate_subscale_scores(answers)\n"
  
  # Insert the lookup_results line at the old subscale_scores position
  subscale_line = level_line + 1
  new_lines[subscale_line] = "      lookup_results = calculate_lookup_results(raw_score, subscale_scores, patient_gender, patient_age, scale_type)\n"
  
  # Insert empty line and new t-score logic
  new_lines.insert(subscale_line + 1, "      \n")
  new_lines.insert(subscale_line + 2, "      # Use t-score for interpretation level determination\n")
  new_lines.insert(subscale_line + 3, "      t_score = lookup_results[:total][:t_score]\n")
  new_lines.insert(subscale_line + 4, "      level = determine_interpretation_level(t_score)\n")
  
  # Remove the old duplicate lines that are now moved
  # Need to find and remove the old subscale_scores and lookup_results lines
  lines_to_remove = []
  (subscale_line + 5).upto(new_lines.length - 1) do |i|
    line = new_lines[i]
    if line.strip.start_with?('subscale_scores = calculate_subscale_scores(') ||
       line.strip.start_with?('lookup_results = calculate_lookup_results(')
      lines_to_remove << i
    end
  end
  
  # Remove duplicate lines (in reverse order to maintain indices)
  lines_to_remove.reverse.each do |i|
    new_lines.delete_at(i)
  end
  
  # Write back to file
  File.write('app/services/scoring/srs2.rb', new_lines.join(''))
  puts "Updated calculate method successfully!"
else
  puts "Could not find the level assignment line"
end
