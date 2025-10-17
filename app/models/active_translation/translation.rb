module ActiveTranslation
  class Translation < ApplicationRecord
    belongs_to :translatable, polymorphic: true

    validates :locale, presence: true, uniqueness: { scope: [ :translatable_type, :translatable_id ] }

    serialize :translated_attributes, coder: JSON

    def outdated?
      source_checksum != translatable.translation_checksum
    end
  end
end
