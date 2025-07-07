class List < ApplicationRecord
    belongs_to :user

    validates :name, :type, :user_id,
        presence: true

    validates :name,
        length: { maximum: 50, minimum: 1 },
        format: { with: /\A[a-zA-Z0-9\s\-_]+\z/, message: "can only contain letters, numbers, spaces, and hyphens" }

    validates :description,
        length: { maximum: 250 },
        format: { with: /\A[a-zA-Z0-9\s\-\_\.\,\:\;\?\!\(\)\[\]\{\}\'\"]*\z/, message: "contains invalid characters" }



    validate :list_type_must_be_valid
    # Additional security validations
    # validate :no_suspicious_content
    # validate :no_excessive_special_characters

    scope :public_lists, -> { where(private: false) }
    scope :private_lists, -> { where(private: true) }

    def can_be_deleted?
        true
    end

    def can_be_updated?
        true
    end

    def display_name
        name
    end

    private
    def list_type_must_be_valid
        valid_types = ['DefaultList', 'CustomList'].freeze
        unless valid_types.include?(type)
            errors.add(:type, "must be one of: #{valid_types.join(', ')}")
        end
    end

    # def no_suspicious_content
    #     return if description.blank?

        #     html_patterns = [
        # /<[^>]*>/,                   # Any HTML tags
        # /&[a-zA-Z0-9#]+;/,          # HTML entities
        # /javascript:/i,
        # /vbscript:/i,
        # /data:/i,
        # /about:/i,
        # /file:/i,
        # /ftp:/i
        # ]
        # # SQL injection attempts
        # sql_patterns = [
        # /union\s+select/i,
        # /drop\s+table/i,
        # /insert\s+into/i,
        # /delete\s+from/i,
        # /update\s+set/i,
        # /or\s+1\s*=\s*1/i,
        # /'\s*or\s*'/i
        # ]
    #     # Check for potential XSS attempts
    #     suspicious_patterns = [
    #         /<script/i,
    #         /<\/script/i,
    #         /javascript:/i,
    #         /vbscript:/i,
    #         /onload=/i,
    #         /onerror=/i,
    #         /onclick=/i,
    #         /onmouseover=/i,
    #         /<iframe/i,
    #         /<object/i,
    #         /<embed/i,
    #         /<link/i,
    #         /<meta/i,
    #         /document\.cookie/i,
    #         /document\.write/i,
    #         /eval\(/i,
    #         /expression\(/i
    #     ]
    
    #     suspicious_patterns.each do |pattern|
    #         if description.match?(pattern)
    #             errors.add(:description, "contains potentially harmful content")
    #             break
    #         end
    #     end
    # end

    # def no_excessive_special_characters
    #     return if description.blank?
        
    #     # Prevent spam-like content with excessive special characters
    #     special_char_count = description.scan(/[^a-zA-Z0-9\s]/).length
    #     total_chars = description.length
        
    #     if total_chars > 0 && (special_char_count.to_f / total_chars) > 0.3
    #         errors.add(:description, "contains too many special characters")
    #     end
        
    #     # Prevent excessive repetition of same character
    #     if description.match?(/(.)\1{10,}/)
    #         errors.add(:description, "contains excessive character repetition")
    #     end
    # end

    # Sanitization method (call before saving)
    # def sanitize_description
    # return if description.blank?
    
    # # Remove null bytes and control characters (except newline, carriage return, tab)
    # self.description = description.gsub(/[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]/, '')
    
    # # Normalize whitespace
    # self.description = description.gsub(/\s+/, ' ').strip
    
    # # Remove excessive newlines
    # self.description = description.gsub(/\n{3,}/, "\n\n")
    # end
end
