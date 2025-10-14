class ManualAttributesTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
  end

  test "manual attribute changes don't trigger translations for the manual attribute" do
    employer = employers(:hilton)
    employer.translate_now!

    employer.translatable_locales.each do |locale|
      assert_not_includes(
        JSON.parse(employer.translations.find_by(locale: locale).translated_attributes).keys,
        "name",
        "SETUP: An employer should not have a translated name to start".black.on_yellow
      )
    end

    perform_enqueued_jobs do
      employer.update name: "new name"
    end

    employer.translatable_locales.each do |locale|
      assert_not_includes(
        JSON.parse(employer.translations.find_by(locale: locale).translated_attributes).keys,
        "name",
        "SETUP: An employer should not have a translated name to start".black.on_yellow
      )
    end
  end

  test "manual attributes can be set manually, and don't trigger translations or checksum updates" do
    employer = employers(:hilton)

    perform_enqueued_jobs do
      employer.name_fr = "[fr] Hilton"
    end

    assert_not_empty employer.translations, "An employer should have translations after setting a manual attribute translation".black.on_red
    assert_equal "[fr] Hilton", employer.name_fr, "The name_fr should be set to '[fr] Hilton'".black.on_red

    previous_checksum = employer.translations.first.source_checksum

    perform_enqueued_jobs do
      employer.name_fr = "[fr] a new name"
    end

    assert_equal previous_checksum, employer.translations.first.source_checksum
  end

  test "manual attributes should fall back to the regular attribute if translations don't exist" do
    employer = employers(:hilton)

    perform_enqueued_jobs do
      employer.name_fr = "[fr] Hilton"
      employer.update profile_html: "new profile html"
    end

    assert_not_empty employer.translations, "An employer should have translations after setting a manual attribute translation".black.on_red
    assert_equal "[fr] Hilton", employer.name_fr, "The name_fr should be set to '[fr] Hilton'".black.on_red
    assert_equal employer.name, employer.name_es, "The name_es should be the same as the name when an es translation doesn't exist".black.on_red
  end

  test "auto translation retains manually translated attributes" do
    employer = employers(:hilton)

    perform_enqueued_jobs do
      employer.name_fr = "[fr] Hilton"
    end

    assert_not_empty employer.translations, "An employer should have translations after setting a manual attribute translation".black.on_red

    perform_enqueued_jobs do
      employer.update profile_html: "<h4>Hello World</h4>"
    end

    assert_equal "[fr] Hilton", employer.name_fr, "Updating an auto-translated attribute should not remove manually translated attributes".black.on_red
  end

  test "manually translated attributes fall back whether using the method with locale arg or method without args" do
    employer = employers(:hilton)

    perform_enqueued_jobs do
      employer.name_fr = "[fr] Hilton"
    end

    assert_equal "[fr] Hilton", employer.name_fr, "Calling name_fr should return the fr_translation version of the name".black.on_red
    assert_equal "[fr] Hilton", employer.name(locale: :fr), "Calling name(locale: :fr) should return the fr_translation version of the name".black.on_red
    assert_nil employer.es_translation
    assert_equal employer.name, employer.name_es, "Calling name_es should return the employer name when no es_translation exists".black.on_red
    assert_equal employer.name, employer.name(locale: :es), "Calling name(locale: :es) should return the employer name when no es_translation exists".black.on_red

    perform_enqueued_jobs do
      employer.update profile_html: "hello world"
    end

    employer.reload

    assert_not_nil employer.es_translation
    assert_equal employer.name, employer.name_es, "Calling name_es should return the employer name when an es_translation exists without the name attribute".black.on_red
    assert_equal employer.name, employer.name(locale: :es), "Calling name(locale: :es) should return the employer name when an es_translation exists without the name attribute".black.on_red
  end
end
