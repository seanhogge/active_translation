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

### Into

The `into` argument can be an array of locales, a symbol that matches a method that returns an array of locales, or a Proc that returns an array of locales.

So you could do:

```ruby
translates :content, into: :method_that_returns_locales
```

or

```ruby
translates :content, into: -> { I18n.available_locales - [ I18n.default_locale ] }
```

> `it` is a recent Ruby syntactical grain of sugar. It's the same as `_1` which lets you skip the `{ |arg| arg == :stuff }` repetition

#### Into All

Because translating a model into all the locales your app may define is so common, you can pass `:all` to the `into` argument to achieve the same result as passing `-> { I18n.available_locales - [ I18n.default_locale ] }`.

This means you cannot pass in your own method called "all" as a symbol, of course.

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

Manual attributes have a special setter in the form of `#{locale}_#{attribute_name}`. So in this example, we get `fr_name=` and `es_name=`.

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

At the risk of being obvious: in a real project, you would probably pass the locale as `I18n.locale`, or whatever variable or method that returns the relevant locale.


### Extras

There are a few niceties provided to make ActiveTranslation as flexible as possible.

Ideal world: you won't need them.
Real world: you might need them.

#### Translate on Demand

There may be times when things get hosed. You might need or want to translate the automatic columns manually. You can do this in three ways:

**translate_if_needed**

By calling `translate_if_needed`, you can run the same checks that would occur on update. This is similar to calling `touch`, but it doesn't update the `updated_at` timestamp

**translate!**

By calling `translate!`, you skip all checks for whether a translation is outdated or missing and generate a new translation even if it's already extant and accurate.

**translate_now!(locales)**

By calling `translate_now!` and passing 1 or more locales, you skip all checks for whether a translation is outdated or missing and generate a new translation for the passed locales even if they're already extant and accurate.

**translation_checksum**

By calling `translation_checksum`, you can return the checksum used on a model to determine whether translations are outdated.

**translations_outdated?**

By calling `translations_outdated?`, you can get a true/false if any translation has a checksum that no longer matches the source.

This has limited value, but is exposed in case you need to handle situations in which models change without triggering callbacks.

**translations_missing?**

By calling `translations_missing?`, you can get a true/false if any translations are missing. This is a complex question, and is false unless:

- any automatic translation attributes are not blank
- any automatic translation attributes are missing an entry for any locale

So if you have `translates :title, manual: :name, into: :all` and your app supports `:fr` and `:es`, you will get `true` if:

- the `title` has been translated into `:es`, but not `:fr`
- no translations exist at all

and you will get `false` if:

- the `title` column is blank (`nil` or empty string)
- the `title` column has been fully translated but the `name` column has not been (manual attributes are ignored)
- the `title` column has been fully translated, but the `title` column has changed since the translation in a way that doesn't trigger callbacks

This has limited value, but is exposed in case you need to handle situations in which models change without triggering callbacks.


#### Introspection

You can call `translation_config` on a model or instance to see what you've set up for translations. You'll see something like:

```ruby
> Page.translation_config
=> {attributes: [:title, :heading, :subhead, :content], manual_attributes: [], locales: :all, unless: nil, if: :published?}

> Category.translation_config
=> {attributes: [:name, :short_name],
 manual_attributes: [],
 locales: #<Proc:0x000000012231a2b8 /path/to/projects/active_translation/app/models/category.rb:67 (lambda)>,
 unless: nil,
 if: nil}

> Widget.translation_config
=> {attributes: [:title, :headline, :ad_html],
 manual_attributes: [],
 locales: [:es, :fr],
 unless: #<Proc:0x00000001228fea58 /path/to/projects/active_translation/app/models/widget.rb:42 (lambda)>,
 if: nil}

> Widget.last.translation_config
=> {attributes: [:title, :headline, :ad_html],
 manual_attributes: [],
 locales: [:es, :fr],
 unless: #<Proc:0x00000001228fea58 /path/to/projects/active_translation/app/models/widget.rb:42 (lambda)>,
 if: nil}

> Account.translation_config
=> {attributes: [:profile_html], manual_attributes: ["name"], locales: :method_that_returns_locales, unless: nil, if: nil}
```


## Contributing

Fork the repo, make your changes, make a pull request.


## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
