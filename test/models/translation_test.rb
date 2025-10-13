require "test_helper"

class TranslatableTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "outdated? returns true if checksums don't match" do
    employer = employers(:hilton)

    employer.translate_now!

    employer.translations.last.update(source_checksum: :mismatch)

    assert_not employer.translations.first.outdated?
    assert employer.translations.last.outdated?
  end

  test "a translation is valid with a source_checksum and invalid without" do
    category = categories(:admin)

    translation = category.translations.new(
      locale: :es,
      translated_attributes: {
        name: "[es] name",
        short_name: "[es] short_name"
      }
    )

    assert_not translation.valid?

    translation.source_checksum = :checksum

    assert translation.valid?
  end

  test "a translatable can only have a single translation per locale" do
    page = pages(:home_page)

    page.translate_now!

    translation = page.translations.new(
      locale: page.translatable_locales.first,
      source_checksum: :source_checksum,
      translated_attributes: {
        title: :asdf,
        heading: :asdf,
        subhead: :asdf,
        content: :asdf
      }
    )

    assert_not translation.valid?

    translation.locale = :de

    assert translation.valid?
  end
end
