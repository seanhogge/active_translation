class Job < ApplicationRecord
  translates :title, :headline, :ad_html, into: %i[es fr], unless: -> { posted_status != "posted" }

  enum :posted_status, {
    draft: "draft",
    posted: "posted",
    expired: "expired",
  }
end
