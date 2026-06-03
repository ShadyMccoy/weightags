class CreateLoads < ActiveRecord::Migration[8.1]
  def change
    create_table :loads do |t|
      # Goods flow sender -> receiver. This orientation is fixed regardless of
      # which party is logged in (sender-left / receiver-right invariant).
      t.references :sender_org, null: false, foreign_key: { to_table: :orgs }
      t.references :receiver_org, null: false, foreign_key: { to_table: :orgs }

      # Load-level identity, factored out of the two tags.
      t.string :bol, null: false
      t.date :ship_date
      t.string :commodity
      t.string :truck
      t.string :driver

      t.integer :state, null: false, default: 0

      # Canonical agreed values (null until resolved). Stored in pounds.
      t.decimal :canonical_gross, precision: 12, scale: 2
      t.decimal :canonical_tare, precision: 12, scale: 2
      t.decimal :canonical_net, precision: 12, scale: 2

      # Tolerance snapshot at pairing time, for deterministic delta colouring.
      t.integer :tolerance_bps, null: false, default: 50

      # Resolution provenance.
      t.integer :resolution
      t.references :resolved_by, foreign_key: { to_table: :users }
      t.datetime :resolved_at

      # Dispute context.
      t.string :dispute_reason
      t.text :dispute_notes

      # Dispute-clock fields (B5 — schema present, scheduler deferred).
      t.datetime :clock_started_at
      t.datetime :clock_due_at

      t.timestamps
    end

    # One Load per BOL between a given sender/receiver pair.
    add_index :loads, [ :sender_org_id, :receiver_org_id, :bol ], unique: true,
      name: "index_loads_on_pair_and_bol"
    add_index :loads, :bol
    add_index :loads, :state
  end
end
