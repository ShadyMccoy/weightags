class CreateOrgs < ActiveRecord::Migration[8.1]
  def change
    create_table :orgs do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.string :domain
      t.string :tax_id
      # Ghost orgs are placeholders created when tags are addressed to a partner
      # who hasn't joined yet (A5). They are claimed via magic link later.
      t.boolean :claimed, null: false, default: true

      t.timestamps
    end
    add_index :orgs, :slug, unique: true
    add_index :orgs, :domain
  end
end
