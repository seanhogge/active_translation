module ActiveTranslation
  module Translatable
    extend ActiveSupport::Concern

    class_methods do
      def translates(*attributes, manual: [], into:, unless: nil, if: nil)
        @translation_config ||= {}
        @translation_config[:attributes] = attributes
        @translation_config[:manual_attributes] = Array(manual)
        @translation_config[:locales] = into
        @translation_config[:unless] = binding.local_variable_get(:unless)
        @translation_config[:if] = binding.local_variable_get(:if)

        has_many :translations, class_name: "ActiveTranslation::Translation", as: :translatable, dependent: :destroy

        delegate :translation_config, to: :class
        delegate :translatable_attribute_names, to: :class
        delegate :translatable_locales, to: :class

        after_commit :translate_if_needed, on: [ :create, :update ]

        # Generate locale-specific methods such as fr_translation or de_translation
        into.each do |locale|
          define_method("#{locale}_translation") do
            translations.find_by(locale: locale.to_s)
          end
        end

        # Override attribute methods so that they accept a locale argument
        attributes.each do |attr|
          define_method(attr) do |locale: nil|
            if locale && translation = translations.find_by(locale: locale.to_s)
              JSON.parse(translation.translated_attributes)[attr.to_s]
            else
              super()
            end
          end
        end

        # set up the methods for the manually translated attributes
        Array(manual).each do |attr|
          define_method("#{attr}") do |locale: nil|
            if locale && translation = translations.find_by(locale: locale.to_s)
              JSON.parse(translation.translated_attributes)[attr.to_s].presence || read_attribute(attr)
            else
              read_attribute(attr)
            end
          end

          into.each do |locale|
            define_method("#{attr}_#{locale}=") do |value|
              translation = translations.find_or_initialize_by(translatable_type: self.class.name, translatable_id: self.id, locale: locale.to_s)
              attrs = translation.translated_attributes ? JSON.parse(translation.translated_attributes) : {}
              attrs[attr.to_s] = value
              translation.translated_attributes = attrs.to_json
              translation.source_checksum ||= translation_checksum
              translation.save!
            end

            define_method("#{attr}_#{locale}") do
              translation = translations.find_by(locale: locale.to_s)
              return read_attribute(attr) unless translation

              JSON.parse(translation.translated_attributes)[attr.to_s].presence || read_attribute(attr)
            end
          end
        end
      end

      def translatable_attribute_names
        translation_config[:attributes]
      end

      def translatable_locales
        translation_config[:locales]
      end

      def translation_config
        @translation_config
      end
    end

    def translate_if_needed
      translations.delete_all and return unless conditions_met?

      return unless translatable_attributes_changed? || condition_checks_changed? || translations_outdated? || translations_missing?

      translatable_locales.each do |locale|
        translation = translations.find_or_initialize_by(locale: locale.to_s)

        if translation.new_record? || translation.outdated?
          TranslationJob.perform_later(self, locale.to_s, translation_checksum)
        end
      end
    end

    def translate!
      translatable_locales.each do |locale|
        TranslationJob.perform_later(self, locale.to_s, translation_checksum)
      end
    end

    def translate_now!
      translatable_locales.each do |locale|
        TranslationJob.perform_now(self, locale.to_s, translation_checksum)
      end
    end

    def translation_checksum
      values = translatable_attribute_names.map { |attr| read_attribute(attr).to_s }
      Digest::MD5.hexdigest(values.join)
    end

    # translations are "missing" if they are not manual, the translatable attribute isn't blank
    # and there's no translation for that attribute for all locales
    def translations_missing?
      translatable_locales.each do |locale|
        translatable_attribute_names.each do |attribute|
          next if read_attribute(attribute).blank?

          return true unless translation = translations.find_by(locale: locale)
          return true unless JSON.parse(translation.translated_attributes).keys.include?(attribute)
        end
      end

      false
    end

    def translations_outdated?
      return true if translations.map(&:outdated?).any?

      false
    end

    private

    def condition_checks_changed?
      saved_changes.any? && conditions_exist? && conditions_met?
    end

    def conditions_exist?
      return true if translation_config[:if] || translation_config[:unless]

      false
    end

    # returns true if all conditions are met, or if there are no conditions
    def conditions_met?
      if_condition_met? && unless_condition_met?
    end

    def evaluate_condition(condition)
      case condition
      when Symbol
        send(condition)
      when Proc
        instance_exec(&condition)
      when nil
        true
      else
        false
      end
    end

    # returns true if condition is met or there is no condition
    def if_condition_met?
      return true unless translation_config[:if]

      evaluate_condition(translation_config[:if])
    end

    def translatable_attributes_changed?
      saved_changes.any? && saved_changes.keys.intersect?(translatable_attribute_names.map(&:to_s))
    end

    # returns true if condition is met or there is no condition
    def unless_condition_met?
      return true unless translation_config[:unless]

      !evaluate_condition(translation_config[:unless])
    end
  end
end
