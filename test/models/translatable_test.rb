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
    job = jobs(:sales)

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

  test "a model can be `translated_now!` into a specific locale" do
    employer = employers(:hilton)
    specific_locale = employer.translatable_locales.first
    skipped_locale = employer.translatable_locales.last

    assert_empty employer.translations, "SETUP: the employer should start with no translations".black.on_yellow
    assert_not_equal specific_locale, skipped_locale, "SETUP: the employer should have at least two `translatable_locales`".black.on_yellow

    employer.translate_now!(specific_locale)

    assert(
      employer.send("#{specific_locale}_translation"),
      "There should be a #{specific_locale}_translation after calling `translate_now!(#{specific_locale})`".black.on_red
    )
    assert_equal(
      employer.translatable_attribute_names.map(&:to_s),
      employer.send("#{specific_locale}_translation").translated_attributes.keys,
      "There should be a #{specific_locale} version of `profile_html` after calling `translate_now!(#{specific_locale})`".black.on_red
    )

    assert_nil(
      employer.send("#{skipped_locale}_translation"),
      "There should not be a #{skipped_locale}_translation after calling `translate_now!(#{specific_locale})`".black.on_red
    )
  end

  test "a model can pass :all to `into` to use all available locales except the default" do
    page = pages(:home_page)

    assert_equal(
      I18n.available_locales - [ I18n.default_locale ],
      page.translatable_locales
    )
    assert_equal(
      :all,
      page.translation_config[:locales]
    )
  end

  test "a model is translated on calling `touch`" do
    category = categories(:admin)

    assert_empty category.translations, "A category should start with no translations".black.on_yellow

    perform_enqueued_jobs do
      category.touch
    end

    assert_not_empty(
      category.translations,
      "A category should have translations after calling `touch`".black.on_red
    )
  end

  test "translations_missing? is true if any automatic attributes are not translated" do
    employer = employers(:hilton)

    assert_empty employer.translations, "SETUP: The employer should start with no translations".black.on_yellow
    assert(
      employer.translatable_locales.many?,
      "SETUP: The employer should have more than one translatable locale".black.on_yellow
    )

    assert(
      employer.translations_missing?,
      "`translations_missing?` should be true when no translations are present".black.on_red
    )

    employer.translate_now!(locale: employer.translatable_locales.first)

    assert(
      employer.translations_missing?,
      "`translations_missing?` should still be true when only some translations are present".black.on_red
    )

    employer.translate_now!

    assert_not(
      employer.translations_missing?,
      "`translations_missing?` should be false when all translations are present".black.on_red
    )
  end

  test "`manual_translations_missing?` is true if any automatic or manual attributes are not translated" do
    employer = employers(:hilton)

    assert_empty employer.translations, "SETUP: The employer should start with no translations".black.on_yellow
    assert(
      employer.translatable_locales.many?,
      "SETUP: The employer should have more than one translatable locale".black.on_yellow
    )

    assert(
      employer.manual_translations_missing?,
      "`translations_missing?(:all)` should be true when no translations are present".black.on_red
    )

    employer.send("#{employer.translatable_locales.first}_name=", :asdf)

    assert(
      employer.manual_translations_missing?,
      "`translations_missing?(:all)` should be true when only one manual attribute translation is present".black.on_red
    )

    employer.translatable_locales.each do |locale|
      employer.send("#{locale}_name=", :asdf)
    end

    assert_not(
      employer.manual_translations_missing?,
      "`translations_missing?(:all)` should be false when all manual attribute translations and no automatic attributes are present".black.on_red
    )
  end

  test "fully_translated? is true if any automatic attributes are not translated" do
    employer = employers(:hilton)

    assert_empty employer.translations, "SETUP: The employer should start with no translations".black.on_yellow
    assert(
      employer.translatable_locales.many?,
      "SETUP: The employer should have more than one translatable locale".black.on_yellow
    )

    assert_not(
      employer.fully_translated?,
      "`fully_translated?` should be false when no translations are present".black.on_red
    )

    employer.translate_now!(locale: employer.translatable_locales.first)

    assert_not(
      employer.fully_translated?,
      "`fully_translated?` should be false when only some translations are present".black.on_red
    )

    employer.translate_now!

    assert(
      employer.fully_translated?,
      "`fully_translated?` should be true when all automatic attribute translations are present".black.on_red
    )
  end

  test "`fully_translated(:manual)?` is true if all manual attributes are translated" do
    employer = employers(:hilton)

    assert_empty employer.translations, "SETUP: The employer should start with no translations".black.on_yellow
    assert(
      employer.translatable_locales.many?,
      "SETUP: The employer should have more than one translatable locale".black.on_yellow
    )

    assert_not(
      employer.fully_translated?(:manual),
      "`fully_translated?(:manual)` should be false when no translations are present".black.on_red
    )

    employer.send("#{employer.translatable_locales.first}_name=", :asdf)

    assert_not(
      employer.fully_translated?(:manual),
      "`fully_translated?(:manual)` should be false when only one manual attribute translation is present".black.on_red
    )

    employer.translatable_locales.each do |locale|
      employer.send("#{locale}_name=", :asdf)
    end

    assert(
      employer.fully_translated?(:manual),
      "`fully_translated?(:manual)` should be true when all manual attribute translations and no automatic attributes are present".black.on_red
    )
  end

  test "`fully_translated(:all)?` is true if all manual and automatic attributes are translated" do
    employer = employers(:hilton)

    assert_empty employer.translations, "SETUP: The employer should start with no translations".black.on_yellow
    assert(
      employer.translatable_locales.many?,
      "SETUP: The employer should have more than one translatable locale".black.on_yellow
    )

    assert_not(
      employer.fully_translated?(:all),
      "`fully_translated?(:all)` should be false when no translations are present".black.on_red
    )

    employer.send("#{employer.translatable_locales.first}_name=", :asdf)

    assert_not(
      employer.fully_translated?(:all),
      "`fully_translated?(:all)` should be false when only one manual attribute translation is present".black.on_red
    )

    employer.translate_now!(employer.translatable_locales.first)

    assert_not(
      employer.fully_translated?(:all),
      "`fully_translated?(:all)` should be false when only one manual attribute translation and only one automatic attribute translation is present".black.on_red
    )

    employer.translatable_locales.each do |locale|
      employer.send("#{locale}_name=", :asdf)
    end
    employer.translate_now!

    assert(
      employer.fully_translated?(:all),
      "`fully_translated?(:all)` should be true when all manual attribute translations and all automatic attributes are present".black.on_red
    )
  end

  test "passing an invalid argument to `fully_translated?` raises an ArgumentError" do
    employers(:hilton).fully_translated?(:auto)
    employers(:hilton).fully_translated?(:auto_only)
    employers(:hilton).fully_translated?(:manual)
    employers(:hilton).fully_translated?(:manual_only)
    employers(:hilton).fully_translated?(:all)
    employers(:hilton).fully_translated?(:include_manual)
    employers(:hilton).fully_translated?

    assert_raises ArgumentError do
      employers(:hilton).fully_translated?(:not_a_valid_argument)
    end
  end

  test "`translations_missing?` is false if conditions are not met" do
    job = jobs(:sales)
    page = pages(:home_page)

    assert_equal "draft", job.posted_status, "SETUP: The job should be in draft status".black.on_yellow
    assert_empty(
      job.translations,
      "SETUP: The job should start with no translations present".black.on_yellow,
    )
    assert_empty(
      page.translations,
      "SETUP: The page should start with no translations present".black.on_yellow,
    )

    assert_not job.translations_missing?, "A job should return false for `translations_missing?` if its conditions aren't met".black.on_red
    assert_not page.translations_missing?, "A page should return false for `translations_missing?` if its conditions aren't met".black.on_red
  end

  test "`manual_translations_missing?` is false if conditions are not met" do
    job = jobs(:sales)
    page = pages(:home_page)

    assert_equal "draft", job.posted_status, "SETUP: The job should be in draft status".black.on_yellow
    assert_empty(
      job.translations,
      "SETUP: The job should start with no translations present".black.on_yellow,
    )
    assert_empty(
      page.translations,
      "SETUP: The page should start with no translations present".black.on_yellow,
    )

    assert_not job.manual_translations_missing?, "A job should return false for `manual_translations_missing?` if its conditions aren't met".black.on_red
    assert_not page.manual_translations_missing?, "A page should return false for `manual_translations_missing?` if its conditions aren't met".black.on_red
  end

  test "`fully_translated?` is true if conditions are not met" do
    job = jobs(:sales)
    page = pages(:home_page)

    assert_equal "draft", job.posted_status, "SETUP: The job should be in draft status".black.on_yellow
    assert_empty(
      job.translations,
      "SETUP: The job should start with no translations present".black.on_yellow,
    )
    assert_empty(
      page.translations,
      "SETUP: The page should start with no translations present".black.on_yellow,
    )

    assert job.fully_translated?, "A job should return true for `fully_translated?` if its conditions aren't met".black.on_red
    assert page.fully_translated?, "A page should return true for `fully_translated?` if its conditions aren't met".black.on_red
  end

  test "`fully_translated?(:all)` is true if conditions are not met" do
    job = jobs(:sales)
    page = pages(:home_page)

    assert_equal "draft", job.posted_status, "SETUP: The job should be in draft status".black.on_yellow
    assert_empty(
      job.translations,
      "SETUP: The job should start with no translations present".black.on_yellow,
    )
    assert_empty(
      page.translations,
      "SETUP: The page should start with no translations present".black.on_yellow,
    )

    assert job.fully_translated?(:all), "A job should return true for `fully_translated?` if its conditions aren't met".black.on_red
    assert page.fully_translated?(:all), "A page should return true for `fully_translated?` if its conditions aren't met".black.on_red
  end

  test "`outdated_translations` returns an array of outdated translations based on checksum" do
    employer = employers(:hilton)
    employer.translate_now!

    assert_not employer.translations_outdated?, "SETUP: The employer should start with current translations".black.on_yellow

    employer.update_column(:profile_html, "New profile without triggering a callback")

    assert_equal(
      employer.translations,
      employer.outdated_translations,
      "All translations should be outdated after an update to a translated column that doesn't trigger callbacks".black.on_red,
    )

    employer.translate_now!(employer.translatable_locales.first)

    employer.reload

    assert_equal(
      employer.translations.excluding(employer.translations.where(locale: employer.translatable_locales.first)),
      employer.outdated_translations,
      "Translations should be outdated if they don't match the new translatable attributes".black.on_red,
    )
  end

  test "a record with a manual translation is still translated if needed" do
    employer = employers(:hilton)

    assert_empty employer.translations, "SETUP: The employer should start with no translations".black.on_yellow
    assert employer.translations_missing?, "SETUP: The employer should start with translations_missing? as `true`".black.on_yellow
    assert_not employer.fully_translated?, "SETUP: The employer should start with fully_translated? as `false`".black.on_yellow

    employer.fr_name = "french name"

    assert_not_empty employer.translations, "The employer should have at least 1 translation after a manual translation assignment".black.on_red
    assert_not_equal employer.name, employer.name(locale: :fr), "The employer should have a different name in the :fr locale".black.on_red
    assert_empty employer.translations.where(locale: :es), "The employer should not have any :es translations after adding a manual :fr translation".black.on_red
    assert_equal employer.name, employer.name(locale: :es), "The employer's :es name should be the same as the english name since no :es name has been provided".black.on_red

    perform_enqueued_jobs do
      employer.translate_if_needed
    end

    employer.reload

    assert employer.fully_translated?, "The employer should be fully_translated after calling `translate_if_needed`".black.on_red
    assert_not_equal employer.name, employer.name(locale: :fr), "The employer should have a different name in the :fr locale after being auto translated".black.on_red
    assert_not_equal employer.profile_html, employer.profile_html(locale: :fr), "The employer should have a different profile_html in the :fr locale after auto translation".black.on_red
    assert_not_equal employer.profile_html, employer.profile_html(locale: :es), "The employer should have a different profile_html in the :es locale after auto translation".black.on_red
    assert_not_empty employer.translations.where(locale: :es), "The employer should have :es translations after auto translation".black.on_red
  end
end
