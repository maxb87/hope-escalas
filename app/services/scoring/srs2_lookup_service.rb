# frozen_string_literal: true

module Scoring
  class Srs2LookupService
    class << self
      # Lookup t-score for total score
      def lookup_total_t_score(raw_score, gender:, age:, scale_type:)
        table = select_lookup_table(gender: gender, age: age, scale_type: scale_type)
        return nil unless table

        normalized_score = normalize_raw_score(raw_score, table)
        row = table.find { |r| r[:raw_score] == normalized_score }
        row&.dig(:total_t)
      end

      # Lookup percentile for total score
      def lookup_total_percentile(raw_score, gender:, age:, scale_type:)
        table = select_lookup_table(gender: gender, age: age, scale_type: scale_type)
        return nil unless table

        normalized_score = normalize_raw_score(raw_score, table)
        row = table.find { |r| r[:raw_score] == normalized_score }
        row&.dig(:total_percentile)
      end

      # Lookup t-score for a specific subscale
      def lookup_subscale_t_score(raw_score, subscale:, gender:, age:, scale_type:)
        table = select_lookup_table(gender: gender, age: age, scale_type: scale_type)
        return nil unless table

        normalized_score = normalize_raw_score(raw_score, table)
        row = table.find { |r| r[:raw_score] == normalized_score }
        subscale_key = normalize_subscale_key("#{subscale}_t")
        row&.dig(subscale_key)
      end

      # Lookup percentile for a specific subscale
      def lookup_subscale_percentile(raw_score, subscale:, gender:, age:, scale_type:)
        table = select_lookup_table(gender: gender, age: age, scale_type: scale_type)
        return nil unless table

        normalized_score = normalize_raw_score(raw_score, table)
        row = table.find { |r| r[:raw_score] == normalized_score }
        subscale_key = normalize_subscale_key("#{subscale}_percentile")
        row&.dig(subscale_key)
      end

      private

      # Normalize raw_score to ensure it's within table bounds
      def normalize_raw_score(raw_score, table)
        return 0 if raw_score < 0

        max_score = get_max_raw_score(table)
        return max_score if raw_score > max_score

        raw_score
      end

      # Get the maximum raw_score available in the table
      def get_max_raw_score(table)
        return 0 if table.empty?

        table.map { |row| row[:raw_score] }.compact.max || 0
      end

      # Normalize subscale key to handle typos in CSV headers
      def normalize_subscale_key(key)
        # Handle the typo in CSV: social_comunication -> social_communication
        normalized_key = key.to_s.gsub("social_comunication", "social_communication")
        normalized_key.to_sym
      end

      # Select the appropriate lookup table based on patient demographics
      def select_lookup_table(gender:, age:, scale_type:)
        if age < 7
          preschool_table
        elsif age >= 7 && age < 18
          gender == "female" ? school_female_table : school_male_table
        else # age >= 18
          scale_type == "self_report" ? adult_auto_table : adult_hetero_table
        end
      end

      # Cache and load preschool lookup table
      def preschool_table
        @preschool_table ||= load_csv_table("srs2_lookup_preschool_t_percentile.csv")
      end

      # Cache and load school female lookup table
      def school_female_table
        @school_female_table ||= load_csv_table("srs2_lookup_school_female_t_percentile.csv")
      end

      # Cache and load school male lookup table
      def school_male_table
        @school_male_table ||= load_csv_table("srs2_lookup_school_male_t_percentile.csv")
      end

      # Cache and load adult auto (self-report) lookup table
      def adult_auto_table
        @adult_auto_table ||= load_csv_table("srs2_lookup_adult_t_percentile_auto.csv")
      end

      # Cache and load adult hetero (parent-report) lookup table
      def adult_hetero_table
        @adult_hetero_table ||= load_csv_table("srs2_lookup_adult_t_percentile_hetero.csv")
      end

      # Load CSV table and convert to array of hashes
      def load_csv_table(filename)
        require "csv"
        file_path = Rails.root.join("config", "data", "srs2", filename)

        unless File.exist?(file_path)
          Rails.logger.error "SRS-2 lookup table not found: #{filename}"
          return []
        end

        CSV.read(file_path, headers: true).map do |row|
          # Filter out empty columns and convert to hash
          filtered_row = row.to_h.reject { |k, v| k.blank? || v.blank? }

          filtered_row.transform_keys(&:to_sym).transform_values do |value|
            # Convert empty strings to nil, then convert to integer if numeric
            if value.blank?
              nil
            elsif value.match?(/^\d+$/)
              value.to_i
            else
              value
            end
          end
        end
      rescue => e
        Rails.logger.error "Error loading SRS-2 lookup table #{filename}: #{e.message}"
        []
      end
    end
  end
end
