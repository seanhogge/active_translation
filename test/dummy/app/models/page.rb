class Page < ApplicationRecord
  translates :title, :heading, :subhead, :content, into: %i[es fr], if: :published?
end
