class Category < ApplicationRecord
  translates :name, :short_name, into: -> { I18n.available_locales.reject { it == I18n.default_locale } }
end
