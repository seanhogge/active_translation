module ActiveTranslation
  class TranslationJob < ActiveJob::Base
    queue_as :default

    def perform(object, locale, checksum)
      translated_data = {}

      object.translatable_attributes.each do |attribute|
        source_text = object.read_attribute(attribute)
        translated_data[attribute.to_s] = translate_text(source_text, locale)
      end

      translation = object.translations
        .find_or_initialize_by(
          locale: locale,
        )

      existing_data =
        begin
          translation.translated_attributes.present? ? JSON.parse(translation.translated_attributes) : {}
        rescue JSON::ParserError
          {}
        end

      merged_attributes = existing_data.merge(translated_data)

      translation.update!(
        translated_attributes: merged_attributes.to_json,
        source_checksum: checksum
      )
    end

    private

    def translate_text(text, target_locale)
      return "[#{target_locale}] #{text}" if Rails.env.test?

      ActiveTranslation::GoogleTranslate.translate(target_language_code: target_locale, text: text)
    end
  end
end
