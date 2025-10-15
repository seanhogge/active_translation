require "test_helper"

class TranslatableTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
  end

  test "a model has_many translations when the translates macro is added" do
    category = categories(:admin)

    assert_empty category.translations, "SETUP: the category record should start with no translations".black.on_yellow

    perform_enqueued_jobs do
      category.update name: "administrative"
    end

    assert_not_empty category.translations, "The category should have translations after updating the name".black.on_red
    assert_equal "[es] #{category.name}", category.name(locale: :es), "The category should have an es translation after updating the name".black.on_red
    assert_equal "[fr] #{category.name}", category.name(locale: :fr), "The category should have an fr translation after updating the name".black.on_red
    assert category.fr_translation, "The category should have an fr_translation after updating the name".black.on_red
    assert category.es_translation, "The category should have an es_translation after updating the name".black.on_red
  end

  test "a model is not translated when a non-translated attribute changes" do
    category = categories(:admin)
    category.translate_now!

    category.reload
    assert_not category.translations_outdated?, "SETUP: the category record should start fully translated".black.on_yellow

    category.update path: :asdf

    assert_not category.translations_outdated?, "The category record should not have outdated translations after updating the path".black.on_red
  end

  test "a model with an if constraint is translated when it's toggled to true, and untranslated when toggled to false" do
    page = pages(:home_page)

    perform_enqueued_jobs do
      page.update title: "new title"
    end

    assert_empty page.translations, "A page that isn't published shouldn't be translated".black.on_red

    perform_enqueued_jobs do
      page.update published: true
    end

    assert_not_empty page.translations, "A page should be translated if the only constraint changes to true".black.on_red

    page.reload

    perform_enqueued_jobs do
      page.update published: false
    end

    assert_empty page.translations, "Toggling the only constraint to false should destroy existing translations".black.on_red
  end

  test "a model with an unless (proc) constraint is translated when it's toggled to false, and untranslated when toggled to true" do
    job = jobs(:chef)

    perform_enqueued_jobs do
      job.update title: "new title"
    end

    assert_empty job.translations, "A job that isn't posted shouldn't be translated".black.on_red

    perform_enqueued_jobs do
      job.update posted_status: "posted"
    end

    assert_not_empty job.translations, "A job should be translated if the unless constraint changes to false".black.on_red

    job.reload

    perform_enqueued_jobs do
      job.update posted_status: "expired"
    end

    assert_empty job.translations, "Toggling the unless constraint to true should destroy existing translations".black.on_red
  end

  test "creating a new translatable record creates translations" do
    employer = perform_enqueued_jobs do
      Employer.create(name: "Hyatt", profile_html: "<p>A great hotel</p>")
    end

    assert_not_empty employer.translations, "Creating a new employer with profile_html should generate translations".black.on_red
  end

  test "creating a new translatable record with blank values does not trigger translation" do
    employer = perform_enqueued_jobs do
      Employer.create(name: "Hyatt", profile_html: nil)
    end

    assert_empty employer.translations, "Creating a new employer with no profile_html should not trigger translations".black.on_red
  end

  test "changing auto translation attributes triggers retranslation" do
    employer = employers(:hilton)

    perform_enqueued_jobs do
      employer.update profile_html: "first profile update"
    end

    assert_not_empty employer.translations, "An employer should have translations after updating the profile_html".black.on_red
    assert_equal "[fr] first profile update", employer.profile_html(locale: :fr)
    assert_equal "[es] first profile update", employer.profile_html(locale: :es)

    employer.reload

    perform_enqueued_jobs do
      employer.update profile_html: "second profile update"
    end

    assert_equal "[fr] second profile update", employer.profile_html(locale: :fr), "A second update to an auto translated attribute should be correctly saved".black.on_red
    assert_equal "[es] second profile update", employer.profile_html(locale: :es), "A second update to an auto translated attribute should be correctly saved".black.on_red
  end

  test "translations_outdated? doesn't check missing translations" do
    employer = employers(:hilton)

    assert_not employer.translations_outdated?
  end

  test "translate_if_needed can be called outside a callback without errors" do
    employer = employers(:hilton)

    assert employer.translations.none?

    perform_enqueued_jobs do
      employer.translate_if_needed
    end

    employer.reload
    assert_not_empty employer.translations

    # call it again to cover the case where translations already exist
    perform_enqueued_jobs do
      employer.translate_if_needed
    end
  end

  test "a model can be translated on demand asynchronously" do
    employer = employers(:hilton)

    assert_empty employer.translations

    employer.translatable_locales.each do |locale|
      assert_nil employer.send("#{locale}_translation")
    end

    perform_enqueued_jobs do
      employer.translate_now!
    end

    employer.translatable_locales.each do |locale|
      assert employer.send("#{locale}_translation")
    end
  end

  test "a model can be translated on demand synchronously" do
    employer = employers(:hilton)
    locales = employer.translatable_locales

    assert_empty employer.translations

    locales.each do |locale|
      assert_nil employer.send("#{locale}_translation")
    end

    employer.translate_now!

    locales.each do |locale|
      assert employer.send("#{locale}_translation"), "An employer should have a(n) #{locale}_translation after calling `translate_now!`".black.on_red
    end
  end

  test "translate_if_needed does not retranslate if updated with identical content previously translated" do
    employer = employers(:hilton)
    employer.translate_now!
    assert_not employer.translations_outdated?, "SETUP: The employer should start with up-to-date translations".black.on_yellow

    assert_no_enqueued_jobs do
      employer.update profile_html: employer.profile_html
    end
  end

  test "a model can pass a symbol for the `into` argument to call as a method" do
    employer = employers(:hilton)

    assert employer.translatable_locales
    assert employer.translatable_locales.is_a?(Array)
    assert_equal employer.send(:method_that_returns_locales), employer.translatable_locales
  end

  test "a model can pass a Proc for the `into` argument" do
    category = categories(:admin)

    assert category.translatable_locales
    assert category.translatable_locales.is_a?(Array)
  end
end
