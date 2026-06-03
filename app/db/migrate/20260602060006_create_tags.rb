class CreateTags < ActiveRecord::Migration[8.1]
  def change
    create_table :tags do |t|
      # The org that recorded this measurement (owns the row).
      t.references :org, null: false, foreign_key: true
      # The other party on this load.
      t.references :counterparty_org, null: false, foreign_key: { to_table: :orgs }
      # Which side of the goods flow this org is on for this load.
      t.integer :side, null: false

      # The Load this tag was paired into (set by the matching engine, B1).
      t.references :load, foreign_key: true

      # Load identity / metadata.
      t.string :bol, null: false
      t.date :ship_date
      t.string :truck
      t.string :driver
      t.string :commodity

      # Measurements (pounds).
      t.decimal :gross, precision: 12, scale: 2
      t.decimal :tare, precision: 12, scale: 2
      t.decimal :net, precision: 12, scale: 2
      t.decimal :moisture, precision: 5, scale: 2
      t.string :grade

      # Provenance — the foundation of the audit trail (charter: Tag).
      t.string :weighed_by
      t.string :scale_id
      t.datetime :weighed_at
      t.text :notes

      # Who entered it into WeighTags (distinct from who operated the scale).
      t.references :recorded_by, foreign_key: { to_table: :users }

      t.timestamps
    end

    # One tag per side per BOL within an org's relationship with a counterparty.
    add_index :tags, [ :org_id, :counterparty_org_id, :bol ], unique: true,
      name: "index_tags_on_org_counterparty_bol"
    add_index :tags, :bol
  end
end
