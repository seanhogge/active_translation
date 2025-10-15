class Employer < ApplicationRecord
  translates :profile_html, manual: :name, into: :method_that_returns_locales

  private

  def method_that_returns_locales
    %i[es fr]
  end
end
