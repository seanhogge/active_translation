# ActiveTranslation

ActiveTranslation lets you easily translate ActiveRecord models. With a single line added to that model, you can declare which columns, which locales, and what constraints to allow or prevent translation.


## Installation

Add the gem to your gemfile:

```ruby
gem "active_translation", git: "https://github.com/seanhogge/active_translation"
```

And then bundle:

```bash
bundle
```

Run the installer to add a migration and initializer:

```ruby
rails generate active_translation:install
```

Migrate your primary database:

```ruby
rails db:migrate
```

You will need to restart your rails server and your ActiveJob adapter process (if separate) if it was running when you installed and migrated.


## Configuration

The first step after installation is to configure your Google credentials. ActiveTranslation uses the Google Translate API in the background for translation. This is a bit more than just an API key.

The general idea is:

1. Create a project at https://console.cloud.google.com
1. In “APIs & Services” > “Library” look for “Cloud Translation API”
1. Create a Service Account and download the JSON key file
1. Ensure billing is enabled, and all the other prerequisites that Google requires
1. Extract the necessary data from that JSON file and plug those values into `config/initializers/active_translation.rb` by setting the appropriate environment variables

Feel free to change the names of the environment variables, or to alter that initializer to assign those keys however you like. At Talentronic, we have an `APIConnection` model we use for stuff like that so we grab the credentials from there and assign them.

You could also use something like `dotenv-rails` and create a `.env` file in your various environments.

Or you could use the OS to define them, such as in an `/etc/environment` file.

If you're using Kamal, you probably already have a way to manage secrets and add them to env variables - that works, too.

Obvious reminder: whatever method you use, just make sure it's not committed to any repository, even once. If you do, make sure you get new credentials and expire/delete the credentials that got committed.

That's the hard part!


## Usage

To any ActiveRecord model, add `translates` with a list of columns that should be translated, a list of locales and any constraints.

Simplest form:

```ruby
translates :content, into: %i[es fr de]
```

### If Constraints

An `if` constraint will prevent translating if it returns `false`.

If you have a boolean column like `published`, you might do:

```ruby
translates :content, into: %i[es fr de], if: :published?
```

Or you can define your own method that returns a boolean:

```ruby
translates :content, into: %i[es fr de], if: :record_should_be_translated?
```

Or you can use a Proc:

```ruby
translates :content, into: %i[es fr de], if: -> { content.length > 10 }
```

### Unless Constraints

These work exactly the same as the `if` constraint, but the logic is flipped. If the constraint returns `true` then no translating will take place.

### Constraint Compliance

If your record is updated such that either an `if` or `unless` constraint is toggled, this will trigger the addition _or removal_ of translation data. The idea here is that the constraint controls whether a translation should _exist_, not whether a translation should be performed.

This means if you use a constraint that frequently changes value, you will be paying for half of all change events.

This is intentional. Translations are regenerated any time one of the translated attributes changes. But what about something like a `Post` that shouldn't be translated until it's published? There's no sense in translating it dozens of times as it's edited, but clicking the “publish” button doesn't update the translatable attributes.

So ActiveTranslation watches for the constraint to change so that when the `Post` is published, the translation is performed with no extra effort.

Likewise, if the constraint changes the other way, translations are removed since ActiveTranslation will no longer be keeping those translations up-to-date. Better to have no translation than a completely wrong one.

### Manual Attributes

Sometimes you want to translate an attribute, but it's not something Google Translate or an LLM can handle on their own. For instance, at Talentronic, we have names of businesses that operate in airports. These names have trademarked names that might look like common words, but aren't. These names also have the airport included which can confuse the LLM or API when it's mixed in with the business name.

So we need manual translation attributes:

```ruby
translates :content, manual: :name, into: %i[es fr]
```

Manual attributes have a special setter in the form of `#{attribute_name}_#{locale}=`. So in this example, we get `name_fr=` and `name_es=`.

These attributes never trigger retranslation, and are never checked against the original text - it's entirely up to you to maintain them. However, it does get stored alongside all the other translations, keeping your database tidy and your translation code consistent.

### The Show

Once you have added the `translates` directive with your columns, locales, and constraints and your models have been translated to at least one locale, it's time to actually use them.

If you set:

```ruby
translates :content, manual: :name, into: %i[es fr]
```

on a model like `Post`, then you can do this with an instance of `Post` assigned to `@post`:

```ruby
@post.content(locale: :fr)
```

If the post has an `fr_translation`, then that will be shown. If no `fr_translation` exists, it will show the post's untranslated `content`.

In this way, you'll never have missing values, but you will have the default language version instead of the translated version.

The same goes for manual translations:

```ruby
@post.name(locale: :es)
```

If the `es_translation` association exists, it will use the value for the `name` attribute, or the untranslated `name` if the `es_translation` doesn't exist.

Obviously, you would probably pass the locale as `I18n.locale` in a real situation, or whatever variable or method that returns the relevant locale.


## Contributing

Fork the repo, make your changes, make a pull request.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
