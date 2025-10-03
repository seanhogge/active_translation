class CreateTranslations < ActiveRecord::Migration[7.0]
  def change
    create_table :active_translation_translations do |t|
      t.references :translatable, polymorphic: true, null: false
      t.string :locale, null: false
      t.text :translated_attributes # serialized JSON
      t.string :source_checksum, null: false
      t.timestamps
    end

    add_index :translations, [ :translatable_type, :translatable_id, :locale ],
              unique: true, name: "index_translations_on_translatable_and_locale"
  end
end
