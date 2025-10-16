class Page < ApplicationRecord
  translates :title, :heading, :subhead, :content, into: :all, if: :published?
end
