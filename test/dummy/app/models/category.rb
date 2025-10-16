class Category < ApplicationRecord
  translates :name, :short_name, into: -> { I18n.available_locales - [ I18n.default_locale ] }
end
